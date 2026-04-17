package com.nateb.mymedtimer.math

data class HawkesParameters(
    val mu: Double,     // baseline intensity (misses per day)
    val alpha: Double,  // excitation magnitude
    val beta: Double    // decay rate
)
