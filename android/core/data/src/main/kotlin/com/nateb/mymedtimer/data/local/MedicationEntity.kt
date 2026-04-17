package com.nateb.mymedtimer.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "medications")
data class MedicationEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val dosage: String,
    val colorHex: String,
    val alertStyle: String,
    val isPRN: Boolean,
    val minIntervalMinutes: Int,
    val isActive: Boolean,
    val createdAt: Long
)
