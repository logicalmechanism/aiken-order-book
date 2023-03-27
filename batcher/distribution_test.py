import matplotlib.pyplot as plt
import random
import numpy as np


def calculate_have_want():
    p_0 = random.gauss(2.5, 0.95)
    if p_0 <= 0:
        return calculate_have_want()
    want = random.randint(10000,100000)
    have = int(p_0*want)
    if have < 0 or want < 0:
        return calculate_have_want()
    return have, want

def f(m, x, b):
    return m*x + b

values = []
x = []
y = []
for _ in range(1500):
    p_0 = random.gauss(2.5, 0.95)
    if p_0 <= 0:
        continue
    values.append(p_0)
    have, want = calculate_have_want()
    x.append(want)
    y.append(have)

x = np.array(x)
y = np.array(y)



mean_price = 2.5
slippage1 = 7 # 14.3%
slippage2 = 4 # 25%

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 5))

# Plot the data and the linear line
ax1.plot(x, y, '.k',label='data')
ax1.plot(x, f(mean_price, x, 0), 'b-',label=f'fit line (slope={mean_price}, color=blue)')
ax1.plot(x, f(mean_price*(1-1/slippage1), x, 0), '-g', label=f'fit line (error=14.3%, color=green)')
ax1.plot(x, f(mean_price*(1+1/slippage1), x, 0), '-g')
ax1.plot(x, f(mean_price*(1-1/slippage2), x, 0), '--r', label=f'fit line (error=25%, color=red)')
ax1.plot(x, f(mean_price*(1+1/slippage2), x, 0), '--r')
ax1.set_title("Have-Want Token Distribution Of N Trades")
ax1.set_xlabel("Want Token")
ax1.set_ylabel("Have Token")
ax1.legend()

ax2.hist(values, bins=100)
ax2.set_xlabel("Have-Want Price")
ax2.set_title("Price Distribution For N Trades")

# plt.show()
fig.savefig("images/batcher_bot_test_distribution.png", dpi=300)