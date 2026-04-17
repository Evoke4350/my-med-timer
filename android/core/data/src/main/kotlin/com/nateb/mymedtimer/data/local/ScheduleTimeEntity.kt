package com.nateb.mymedtimer.data.local

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "schedule_times",
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
data class ScheduleTimeEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val medicationId: String,
    val hour: Int,
    val minute: Int
)
