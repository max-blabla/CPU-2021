#include <iostream>
#include <fstream>
#include <sstream>
using namespace std;
int main() {
    ifstream is;
    string dataname="gcd";
    string str = "../bin/bin/"+dataname + ".bin";
    is.open(str);
    int test;
    string tt;

    while(is){
        getline(is,tt);
        stringstream ss(tt);
        while(ss){
            int i;
            ss >> i;
            cout<<i<<'\n';
        }
        cout << tt<<'\n';
    }
}
