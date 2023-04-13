pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

// import "@openzeppelin/contracts/access/Ownable.sol";
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContractDraft {
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
    uint256 iterationLimit = 10; // TODO make it configurable
    mapping(uint256 => Order) internal orders;

    function deposit(uint256 amount) public {
        uint256 remainingAmount = amount;
        uint256 currentId = orders[HEAD].next;
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

        if (remainingAmount > 0) {
            _createOrder(msg.sender, remainingAmount, OrderType.DEPOSIT);
        } else {
            _executeOrder(amount, msg.sender, OrderType.DEPOSIT);
        }
    }

    function withdraw(uint256 amount) public {
        uint256 remainingAmount = amount;
        uint256 currentId = orders[HEAD].next;
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

        if (remainingAmount > 0) {
            _createOrder(msg.sender, remainingAmount, OrderType.WITHDRAW);
        } else {
            _executeOrder(amount, msg.sender, OrderType.WITHDRAW);
        }
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
}
