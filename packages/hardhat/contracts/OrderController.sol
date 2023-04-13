pragma solidity ^0.8.0;

import "./DoublyLinkedList.sol";

contract OrderController {
    using DoublyLinkedList for DoublyLinkedList.List;

    enum OrderType {
        DEPOSIT,
        WITHDRAW
    }

    struct Order {
        uint256 id;
        uint256 amount;
        address user;
        OrderType orderType;
    }

    uint256 internal constant NULL = 0;
    uint256 internal constant HEAD = 0;
    uint256 public nextOrderId = 1;
    uint256 iterationLimit = 10; // TODO make it configurable
    DoublyLinkedList.List internal orderList;
    mapping(uint256 => Order) internal orders;

    function _removeOrder(uint256 orderId) internal {
        orderList.remove(orderId);
        delete orders[orderId];
    }

    function getOrders() public view returns (Order[] memory) {
        uint256 orderCount = getOrderCount();
        Order[] memory orderArray = new Order[](orderCount);

        uint256 currentOrderId = orderList.head;
        uint256 index = 0;

        while (currentOrderId != NULL) {
            orderArray[index] = orders[currentOrderId];
            currentOrderId = orderList.nodes[currentOrderId].next;
            index++;
        }

        return orderArray;
    }

    function getOrderCount() public view returns (uint256) {
        uint256 currentOrderId = orderList.head;
        uint256 orderCount = 0;

        while (currentOrderId != NULL) {
            orderCount++;
            currentOrderId = orderList.nodes[currentOrderId].next;
        }

        return orderCount;
    }

    function _createOrder(
        address user,
        uint256 amount,
        OrderType orderType
    ) internal {
        uint256 orderId = nextOrderId++;
        uint256 prevId = orderList.tail;

        orders[orderId] = Order(orderId, amount, user, orderType);
        orderList.insertAfter(prevId, orderId);
    }

    function deposit(uint256 amount) public {
        uint256 remainingAmount = amount;
        uint256 currentId = orderList.head;
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

                        uint256 nextId = orderList.nodes[currentId].next;
                        // orderList.remove(currentId);
                        _removeOrder(currentId);
                        currentId = nextId;
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
                    uint256 nextId = orderList.nodes[currentId].next;
                    // orderList.remove(currentId);
                    _removeOrder(currentId);
                    currentId = nextId;
                }
            } else {
                currentId = orderList.nodes[currentId].next;
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
        uint256 currentId = orderList.head;
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
                        uint256 nextId = orderList.nodes[currentId].next;
                        // orderList.remove(currentId);
                        _removeOrder(currentId);
                        currentId = nextId;
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
                    uint256 nextId = orderList.nodes[currentId].next;
                    // orderList.remove(currentId);
                    _removeOrder(currentId);
                    currentId = nextId;
                }
            } else {
                currentId = orderList.nodes[currentId].next;
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

    function _validateOrder(Order memory order) internal view returns (bool) {
        // Add your specific validation logic here
        return true;
    }

    function getNumberOfOrders() public view returns (uint256) {
        uint256 currentOrderId = orderList.head;
        uint256 orderCount = 0;

        while (currentOrderId != NULL) {
            orderCount++;
            currentOrderId = orderList.nodes[currentOrderId].next;
        }

        return orderCount;
    }
}
