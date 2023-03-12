#include <stdio.h>


int main() 
{
    int n = 30; 

    if(n == 1){
        printf("1 is neither prime nor composite.");
        return 0;
    }

    int count = 0;         
    for(int i = 2; i < n; i++) 
    {
        if(n % i == 0)
            count++;
    }
    //Check whether Prime or not
    if(count == 0)           
    {
        printf("%d is a prime number.", n);
    }
    else
    {
        printf("%d is not a prime number.", n);
    }
    return 0;
}
