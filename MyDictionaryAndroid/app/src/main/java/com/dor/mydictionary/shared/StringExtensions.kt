package com.dor.mydictionary.shared

fun String.removeHtmlTags(): String {
    return this.replace(Regex("<[^>]+>"), "")
}