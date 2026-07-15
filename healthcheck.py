"""Simple local health probe for the assistant."""
def healthy() -> bool:
    return True
if __name__ == "__main__":
    print("ok" if healthy() else "fail")
