package com.example.chainalarm

data class AlarmChain(
    val id: Int,
    val originalTimes: List<Long>,
    var currentTimes: List<Long>,
    val interval: Long = 30 * 60 * 1000
)
