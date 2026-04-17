package com.nateb.mymedtimer.ui.navigation

sealed class Screen(val route: String) {
    data object MedList : Screen("med_list")
    data object History : Screen("history")
    data object Settings : Screen("settings")
    data object AddMed : Screen("add_med")
    data object EditMed : Screen("edit_med/{medId}") {
        fun createRoute(medId: String) = "edit_med/$medId"
    }
}
