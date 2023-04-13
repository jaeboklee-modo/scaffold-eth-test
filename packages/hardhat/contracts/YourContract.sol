pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

contract YourContract {
    enum OrderType {
        DEPOSIT,
        WITHDRAW
    }

    struct Order {
        uint256 id;
        uint256 amount;
        address user;
        OrderType orderType;
        uint256 prev;
        uint256 next;
    }

    uint256 internal constant NULL = 0;
    uint256 internal constant HEAD = 0;
    uint256 internal nextOrderId = 1;
    mapping(uint256 => Order) internal orders;

    function deposit(uint256 tokenAmount, uint256 iterationLimit) public {
        uint256 trancheAmount = expectedTrancheAmount(tokenAmount);

        (
            uint256 remainingTrancheAmount,
            uint256 iterations
        ) = _processWithdrawOrder(trancheAmount, iterationLimit);

        if (iterations == iterationLimit) return;

        if (remainingTrancheAmount > 0) {
            uint256 remainingTokenAmount = expectedTokenAmount(
                remainingTrancheAmount
            );
            _createOrder(msg.sender, remainingTokenAmount, OrderType.DEPOSIT);
        }
    }

    function _processWithdrawOrder(
        uint256 trancheAmount,
        uint256 iterationLimit
    ) internal returns (uint256, uint256) {
        uint256 currentId = orders[HEAD].next;
        uint256 remainingAmount = trancheAmount;
        uint256 iterations = 0;

        while (
            currentId != NULL &&
            remainingAmount > 0 &&
            iterations < iterationLimit
        ) {
            Order memory order = orders[currentId];

            if (order.orderType == OrderType.WITHDRAW) {
                if (_validateOrder(order)) {
                    if (order.amount <= remainingAmount) {
                        remainingAmount -= order.amount;
                        _executeOrder(
                            order.amount,
                            order.user,
                            OrderType.WITHDRAW
                        );
                        _removeOrder(currentId);
                        currentId = order.next;
                    } else {
                        orders[currentId].amount -= remainingAmount;
                        _executeOrder(
                            remainingAmount,
                            order.user,
                            OrderType.WITHDRAW
                        );
                        remainingAmount = 0;
                    }
                } else {
                    _removeOrder(currentId);
                    currentId = order.next;
                }
            } else {
                currentId = order.next;
            }

            iterations++;
        }

        return (remainingAmount, iterations);
    }

    function withdraw(uint256 trancheAmount, uint256 iterationLimit) public {
        uint256 tokenAmount = expectedTokenAmount(trancheAmount);

        (
            uint256 remainingTokenAmount,
            uint256 iterations
        ) = _processDepositOrder(tokenAmount, iterationLimit);

        if (iterations == iterationLimit) return;

        if (remainingTokenAmount > 0) {
            uint256 remainingTrancheAmount = expectedTrancheAmount(
                remainingTokenAmount
            );
            _createOrder(
                msg.sender,
                remainingTrancheAmount,
                OrderType.WITHDRAW
            );
        }
    }

    function _processDepositOrder(
        uint256 amount,
        uint256 iterationLimit
    ) internal returns (uint256, uint256) {
        uint256 currentId = orders[HEAD].next;
        uint256 remainingAmount = amount;
        uint256 iterations = 0;

        while (
            currentId != NULL &&
            remainingAmount > 0 &&
            iterations < iterationLimit
        ) {
            Order memory order = orders[currentId];

            if (order.orderType == OrderType.DEPOSIT) {
                if (_validateOrder(order)) {
                    if (order.amount <= remainingAmount) {
                        remainingAmount -= order.amount;
                        _executeOrder(
                            order.amount,
                            order.user,
                            OrderType.DEPOSIT
                        );
                        _removeOrder(currentId);
                        currentId = order.next;
                    } else {
                        orders[currentId].amount -= remainingAmount;
                        _executeOrder(
                            remainingAmount,
                            order.user,
                            OrderType.DEPOSIT
                        );
                        remainingAmount = 0;
                    }
                } else {
                    _removeOrder(currentId);
                    currentId = order.next;
                }
            } else {
                currentId = order.next;
            }

            iterations++;
        }

        return (remainingAmount, iterations);
    }

    function _executeOrder(
        uint256 amount,
        address user,
        OrderType orderType
    ) internal {
        // Add your specific implementation here
    }

    function _createOrder(
        address user,
        uint256 amount,
        OrderType orderType
    ) internal {
        // uint256 existingOrderId = _findExistingOrder(user, orderType);

        // if (existingOrderId != NULL) {
        //     orders[existingOrderId].amount += amount;
        // } else {
        uint256 orderId = nextOrderId++;
        uint256 prevId = orders[HEAD].prev;

        orders[orderId] = Order(orderId, amount, user, orderType, prevId, NULL);

        if (prevId == NULL) {
            orders[HEAD].next = orderId;
        } else {
            orders[prevId].next = orderId;
        }

        orders[HEAD].prev = orderId;
        // }
    }

    function _removeOrder(uint256 orderId) internal {
        Order storage order = orders[orderId];

        if (order.prev == NULL) {
            orders[HEAD].next = order.next;
        } else {
            orders[order.prev].next = order.next;
        }

        if (order.next == NULL) {
            orders[HEAD].prev = order.prev;
        } else {
            orders[order.next].prev = order.prev;
        }

        delete orders[orderId];
    }

    function _findExistingOrder(
        address user,
        OrderType orderType
    ) internal view returns (uint256) {
        uint256 currentOrderId = orders[HEAD].next;

        while (currentOrderId != NULL) {
            Order storage currentOrder = orders[currentOrderId];
            if (
                currentOrder.user == user && currentOrder.orderType == orderType
            ) {
                return currentOrderId;
            }
            currentOrderId = currentOrder.next;
        }

        return NULL;
    }

    function _validateOrder(Order memory order) internal pure returns (bool) {
        // Add your specific validation implementation here
        return true; // Placeholder, replace with actual validation logic
    }

    function _getOrderCount() internal view returns (uint256) {
        uint256 count = 0;
        uint256 currentOrderId = orders[HEAD].next;

        while (currentOrderId != NULL) {
            count++;
            currentOrderId = orders[currentOrderId].next;
        }

        return count;
    }

    function _getOrders() internal view returns (Order[] memory) {
        uint256 orderCount = _getOrderCount();
        Order[] memory ordersArray = new Order[](orderCount);
        uint256 currentIndex = 0;
        uint256 currentOrderId = orders[HEAD].next;

        while (currentOrderId != NULL) {
            Order storage currentOrder = orders[currentOrderId];
            ordersArray[currentIndex] = currentOrder;
            currentOrderId = currentOrder.next;
            currentIndex++;
        }

        return ordersArray;
    }

    function getOrders() public view returns (Order[] memory) {
        return _getOrders();
    }

    function getTranchePrice() public view returns (uint256) {
        // Replace this with the actual logic to get the tranch price in USDT
        uint256 tranchePrice = (1e18 * 20) / 10;
        return tranchePrice;
    }

    function expectedTokenAmount(
        uint256 trancheAmount
    ) public view returns (uint256) {
        return (trancheAmount * getTranchePrice()) / 1e18;
    }

    function expectedTrancheAmount(
        uint256 tokenAmount
    ) public view returns (uint256) {
        return (tokenAmount * 1e18) / getTranchePrice();
    }
}
