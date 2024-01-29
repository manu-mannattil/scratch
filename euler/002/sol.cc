// com: : ${TMPDIR:=/tmp}
// com: : ${CXX:=c++}
// com: : ${CXXFLAGS:=-Wall -Werror}
// com: \{ ${CXX} {} ${CXXFLAGS} -o ${TMPDIR}/{!}; \} && ${TMPDIR}/{!} {@}

#include <iostream>
#include <vector>

using namespace std;

vector<int> fib(unsigned long n, long maxval=10) {
    vector<int> f;
    if (n == 1)
        f.push_back(1);
    else {
        f.push_back(1);
        f.push_back(1);
    }

    int v;
    while (n > 2) {
        if ((v = f.end()[-1] + f.end()[-2]) < maxval)
            f.push_back(v);
        n--;
    }

    return f;
}

struct res {
    unsigned int n;
    long f;
};
res fibn(unsigned int n, long maxval=1e10) {
    if (n == 1 or n == 2)
        return {n, 1};

    int a = 1, b = 1, f = 0;
    unsigned int i = 2;
    while (i < n) {
        f = a + b;
        if (f > maxval)
            break;
        a = b;
        b = f;
        i++;
    }

    res r = {i, f};
    return r;
}

int main(int argc, const char* argv[]) {
    // Sum of even fibonacci numbers = sum of odd fibonacci numbers.
    auto r1 = fibn(1000, 4 * 1000 * 1000);
    auto r2 = fibn(r1.n + 2);
    cout << (r2.f - 1)/2 << endl;

    return 0;
}
