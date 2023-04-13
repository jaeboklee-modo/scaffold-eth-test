pragma solidity ^0.8.0;

library DoublyLinkedList {
    struct Node {
        uint256 id;
        uint256 prev;
        uint256 next;
    }

    struct List {
        uint256 head;
        uint256 tail;
        mapping(uint256 => Node) nodes;
    }

    function insertAfter(
        List storage self,
        uint256 prevId,
        uint256 newId
    ) internal {
        Node storage prevNode = self.nodes[prevId];
        Node storage newNode = self.nodes[newId];

        newNode.prev = prevId;
        newNode.next = prevNode.next;

        if (prevNode.next == 0) {
            self.tail = newId;
        } else {
            self.nodes[prevNode.next].prev = newId;
        }
        prevNode.next = newId;

        // Update the head if there is no previous node
        if (prevId == 0) {
            self.head = newId;
        }
    }

    // function insertAfter(
    //     List storage self,
    //     uint256 prevId,
    //     uint256 newId
    // ) internal {
    //     Node storage prevNode = self.nodes[prevId];
    //     Node storage newNode = self.nodes[newId];

    //     newNode.prev = prevId;
    //     newNode.next = prevNode.next;

    //     if (prevNode.next == 0) {
    //         self.tail = newId;
    //     } else {
    //         self.nodes[prevNode.next].prev = newId;
    //     }
    //     prevNode.next = newId;
    // }

    function remove(List storage self, uint256 nodeId) internal {
        Node storage node = self.nodes[nodeId];

        if (node.prev == 0) {
            self.head = node.next;
        } else {
            self.nodes[node.prev].next = node.next;
        }

        if (node.next == 0) {
            self.tail = node.prev;
        } else {
            self.nodes[node.next].prev = node.prev;
        }

        delete self.nodes[nodeId];
    }
}
