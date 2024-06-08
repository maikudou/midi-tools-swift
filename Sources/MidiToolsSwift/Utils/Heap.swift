//
//  Heap.swift
//
//
//  Created by Michael Henkel on 6/7/24.
//

import Foundation

class Heap<T> {
    init(compareBy compare: @escaping (_ a: T, _ b: T) -> Bool) {
        self._compare = compare
    }
    
    public var count:  Int {
        get {
            return self._arr.count;
        }
    }
    
    public func insert(_ value: T) -> Void {
        self._arr.append(value);
        self._bubbleUp(self._arr.count - 1);
    }

    public func pop() -> T? {
        if(self._arr.count==0) {
            return nil
        }
        self._arr.swapAt(0, self._arr.count - 1);
        let returnedValue = self._arr.popLast()
        self._bubbleDown(0)
        return returnedValue;
    }

    public func getTop() -> T? {
        return self._arr.first;
    }
    
    private var _arr: [T] = []
    private var _compare: (_ a: T, _ b: T) -> Bool
    private func _getParentIndex(_ index: Int) -> Int {
        return (index - 1) / 2
    }
    private func _getLeftChildIndex(_ index: Int) -> Int {
        return index * 2 + 1
    }
    private func _getRightChildIndex(_ index: Int) -> Int {
        return index * 2 + 2
    }
    private func _bubbleUp(_ index: Int) -> Void {
        let parentIndex = self._getParentIndex(index);
        if (parentIndex < 0 || parentIndex == index) {
            return;
        }
        if (self._compare(self._arr[index], self._arr[parentIndex])) {
            self._arr.swapAt(index, parentIndex)
            self._bubbleUp(parentIndex)
        }
    }
    private func _bubbleDown(_ index: Int) {
        let leftChildIndex = self._getLeftChildIndex(index)
        let rightChildIndex = self._getRightChildIndex(index)
        var maxChildIndex: Int

        if (rightChildIndex < self._arr.count
            && leftChildIndex < self._arr.count - 1
            && self._compare(self._arr[rightChildIndex], self._arr[leftChildIndex])) {
            maxChildIndex = rightChildIndex
        } else {
            maxChildIndex = leftChildIndex
        }

        if (maxChildIndex >= self._arr.count || maxChildIndex < 0) {
            return;
        }

        if (self._compare(self._arr[maxChildIndex], self._arr[index])) {
            self._arr.swapAt(maxChildIndex, index)
            self._bubbleDown(maxChildIndex)
        }
    }
}
