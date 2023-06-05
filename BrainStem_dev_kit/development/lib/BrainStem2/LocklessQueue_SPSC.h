/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: LockLessQueue_SPSC.h                                      //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: Template implementation of a thread-safe single    //
//              producer, single consumer lock-less queue.         //
//                                                                 //
// build number: source                                            //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// Copyright (c) 2022 Acroname Inc. - All Rights Reserved          //
//                                                                 //
// This file is part of the BrainStem release. See the license.txt //
// file included with this package or go to                        //
// https://acroname.com/software/brainstem-development-kit         //
// for full license details.                                       //
/////////////////////////////////////////////////////////////////////

#ifndef _LocklessQueue_SPSC_H_
#define _LocklessQueue_SPSC_H_

#include <atomic>

namespace Acroname {
    
    /// Template class of a thread-safe queue when used as a single producer,
    /// single consumer queue.
    template <class T>
    class LocklessQueue_SPSC {
    public:
        
        /// Constructor - Creates a queue with the desired buffer size.
        /// Note: Actually buffer size is always buffer
        /// \param bufferSize - Size of queue to create.
        /// Actual size is always bufferSize - 1 because of internal overhead.
        LocklessQueue_SPSC(uint16_t bufferSize = 256) :
        _buffer(new T[bufferSize]),
        _bufferSize(bufferSize),
        _head(0),
        _tail(0)
        { }
        
        /// Destructor - Recovers internal memory.
        ~LocklessQueue_SPSC() {
            delete[] _buffer;
            _buffer = nullptr;
        }
        
        /// Pushes data into the queue.
        /// Should only be called by one thread context
        /// \param value Element to be queued.
        /// \return True on success; False if the buffer is full
        bool push(T value);
        
        /// Pops data off of the queue
        /// Should only be called by one thread context.
        /// \param value Element to be fill from the queue.
        /// \return True on success; False if the buffer is empty
        bool pop(T* value);
        
        /// Queries the number of elements in the queue.
        /// \return Number of element in queue.
        uint16_t size();
        
    private:
        T* _buffer;
        const uint16_t _bufferSize;
        std::atomic<uint16_t> _head;
        std::atomic<uint16_t> _tail;
        
        inline uint16_t _increment(uint16_t value);
    };
    
    
    
    
    template <class T>
    bool LocklessQueue_SPSC<T>::push(T value) {
        uint16_t newHead = _increment(_head);
        if(newHead != _tail) {
            _buffer[newHead] = value;
            _head = newHead;
            return true;
        }
        else { return false; }
    }
    
    template <class T>
    bool LocklessQueue_SPSC<T>::pop(T* value) {
        if(_tail != _head) {
            _tail = _increment(_tail);
            *value = _buffer[_tail];
            return true;
        }
        else { return false; }
    }
    
    template <class T>
    uint16_t LocklessQueue_SPSC<T>::size() {
        uint16_t head = _head;
        uint16_t tail = _tail;
        if(head >= tail)    { return head - tail;                   }
        else                { return (_bufferSize - tail) + head;   }
    }
    
    template <class T>
    inline uint16_t LocklessQueue_SPSC<T>::_increment(uint16_t value) {
        return (((value + 1) < _bufferSize) ? (value + 1) : (0));
    }
}

#endif //_LocklessQueue_SPSC_H_
