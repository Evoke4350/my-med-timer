package com.nateb.mymedtimer.data.local

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "dose_logs",
    foreignKeys = [
        ForeignKey(
            entity = MedicationEntity::class,
            parentColumns = ["id"],
            childColumns = ["medicationId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("medicationId")]
)
data class DoseLogEntity(
    @PrimaryKey
    val id: String,
    val medicationId: String,
    val scheduledTime: Long,
    val actualTime: Long?,
    val status: String
)
