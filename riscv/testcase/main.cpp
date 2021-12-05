#include <iostream>
#include <fstream>
#include <sstream>
using namespace std;
int gcd(int x, int y) {
    if (x%y == 0) return y;
    else return gcd(y, x%y);
}

int main() {
    cout << gcd(10,1) << '\n';
    cout << gcd(34986,3087) << '\n';
    cout <<gcd(2907,1539) << '\n';
    return 0;
}
