package com.nateb.mymedtimer.math

data class MedicationInsight(
    val riskLevel: RiskLevel,
    val missProbability: Double,
    val consistencyScore: Int,
    val suggestedTime: Pair<Int, Int>?,        // (hour, minute)
    val currentScheduledTime: Pair<Int, Int>?,  // (hour, minute)
    val timeDriftMinutes: Int?,
    val recommendedAlertStyle: String
)
