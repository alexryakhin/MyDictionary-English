let logger = Logger()

func debug(_ message: String...) {
    logger.debug(message.joined(separator: " "))
}

func info(_ message: String...) {
    logger.info(message.joined(separator: " "))
}

func warn(_ message: String...) {
    logger.warn(message.joined(separator: " "))
}

// Named fault in order to distinguish it from error objects
func fault(_ message: String...) {
    logger.error(message.joined(separator: " "))
}
