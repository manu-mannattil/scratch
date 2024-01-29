// com: : ${TMPDIR:=/tmp}
// com: : ${CXX:=c++}
// com: : ${CXXFLAGS:=-Wall -Werror -Ofast}
// com: \{ ${CXX} {} ${CXXFLAGS} -o ${TMPDIR}/{!}; \} && ${TMPDIR}/{!} {@}

#include <iostream>
#include <iomanip>
#include <random>
#include <valarray>
#include <cmath>

using namespace std;

random_device rand_dev;
mt19937_64 rand_gen(rand_dev());
normal_distribution<double> normal(0);

inline auto dU(const double& x) {
    return x*x*x - x;
}

inline auto theta(const double& x) {
    if (x <= 0)
        return 0;
    else
        return 1;
}

int main() {
    const auto N = 500 * 1000 * 1000;
    const auto beta = 20.0;
    const auto dt = 0.001;
    const auto gamma = 0.001;
    const auto dw = sqrt(2/beta * dt * gamma);


    valarray<double> x(N);
    valarray<double> v(N);
    x[0] = 0;
    v[0] = 0;

    for (auto i = 0; i < N - 1; i++) {
        x[i + 1] = x[i] + v[i] * dt;
        v[i + 1] = v[i] - dU(x[i]) * dt - gamma * v[i] * dt + normal(rand_gen)*dw;
    }

    auto nu = 0.0;
    for (auto i = 0; i < N - 1; i++) {
        nu += abs(theta(x[i + 1]) - theta(x[i]));
    }
    nu = nu/(dt*(N-1));
    cout << nu << endl;

    return 0;
}
