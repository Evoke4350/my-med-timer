package com.nateb.mymedtimer.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters

@Database(
    entities = [
        MedicationEntity::class,
        ScheduleTimeEntity::class,
        DoseLogEntity::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun medicationDao(): MedicationDao
    abstract fun scheduleTimeDao(): ScheduleTimeDao
    abstract fun doseLogDao(): DoseLogDao
}
