package com.nateb.mymedtimer.common

import androidx.compose.ui.graphics.Color

fun String.toComposeColor(): Color {
    val hex = this.removePrefix("#")
    val int = hex.toLong(16)
    val r = ((int shr 16) and 0xFF) / 255f
    val g = ((int shr 8) and 0xFF) / 255f
    val b = (int and 0xFF) / 255f
    return Color(r, g, b)
}
