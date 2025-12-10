import math

def is_prime(n):
    """
    Checks if a number is prime using trial division.
    
    Args:
        n (int): The number to check.
        
    Returns:
        bool: True if the number is prime, False otherwise.
    """
    # Prime numbers must be greater than 1.
    if n <= 1:
        return False
    
    # Check for divisibility from 2 up to the square root of the number.
    # If a number has a divisor larger than its square root,
    # it must also have one smaller.
    for i in range(2, int(math.sqrt(n)) + 1):
        if n % i == 0:
            return False
            
    # If no divisors are found, the number is prime.
    return True

def find_primes_up_to(limit):
    """
    Finds all prime numbers up to a given limit.
    
    Args:
        limit (int): The upper bound of the search (inclusive).
        
    Returns:
        list: A list of prime numbers found.
    """
    primes = []
    # Iterate through each number up to the limit.
    for num in range(2, limit + 1):
        if is_prime(num):
            primes.append(num)
    return primes

# --- Main execution part of the script ---
if __name__ == "__main__":
    # Set the upper limit for the prime number search.
    search_limit = 10000000
    
    print(f"Searching for prime numbers up to {search_limit}...")
    
    # Find the prime numbers.
    prime_numbers = find_primes_up_to(search_limit)
    
    # Print the results.
    print(f"Found {len(prime_numbers)} primes: {prime_numbers}")