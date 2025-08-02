package com.dor.mydictionary.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.font.Font
import com.dor.mydictionary.R

val sfProRounded = FontFamily(
    Font(R.font.sf_pro_rounded_regular, FontWeight.Normal),
    Font(R.font.sf_pro_rounded_medium, FontWeight.Medium),
    Font(R.font.sf_pro_rounded_bold, FontWeight.Bold)
)
// Set of Material typography styles to start with
val Typography = Typography(
    displayLarge = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Bold,
        fontSize = 57.sp
    ),
    displayMedium = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Bold,
        fontSize = 45.sp
    ),
    displaySmall = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Bold,
        fontSize = 36.sp
    ),
    headlineLarge = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Bold,
        fontSize = 32.sp
    ),
    headlineMedium = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Medium,
        fontSize = 28.sp
    ),
    headlineSmall = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Medium,
        fontSize = 24.sp
    ),
    titleLarge = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Medium,
        fontSize = 20.sp
    ),
    titleMedium = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp
    ),
    titleSmall = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp
    ),
    bodyLarge = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp
    ),
    bodyMedium = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp
    ),
    bodySmall = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp
    ),
    labelLarge = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp
    ),
    labelMedium = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp
    ),
    labelSmall = TextStyle(
        fontFamily = sfProRounded,
        fontWeight = FontWeight.Medium,
        fontSize = 11.sp
    )
)