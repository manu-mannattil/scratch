// com: : ${TMPDIR:=/tmp}
// com: : ${CXX:=c++}
// com: : ${CXXFLAGS:=-Wall -Werror}
// com: \{ ${CXX} {} ${CXXFLAGS} -o ${TMPDIR}/{!}; \} && ${TMPDIR}/{!} {@}

#include <iostream>
#include <vector>
using namespace std;

long facsum(int n, int a, int b) {
    long sum = 0, i = (n - 1) / a, j = (n - 1) / b, k = (n - 1) / (a * b);
    sum += i * (i + 1) / 2 * a;
    sum += j * (j + 1) / 2 * b;
    sum -= k * (k + 1) / 2 * (a * b);

    return sum;
}

int main(int argc, const char* argv[]) {
    // Brute force.
    long sum = 0, n = 10000, a = 3, b = 7;
    for (auto i = 1; i < n; i++)
        if (i % a == 0 or i % b == 0)
            sum += i;

    cout << sum << endl;

    // Optimized.
    cout << facsum(10000, a, b) << endl;

    return 0;
}
