import matplotlib.pyplot as plt
from matplotlib.figure import Figure
import numpy as np
  
# define data values
plt_1 = Figure(figsize=(20, 15))

x1 = [0, 1, 6, 18, 42, 72, 86, 116, 126, 156] # 166, 196, 206, 236, 246, 276
y1 = [0, 1, 2,  3,  4,  3,  4,   3,   4,   3] #   4,   3,   4,   3,   4,   3

x2 = [1, 2, 8, 22, 50, 80, 94, 124, 134, 164] # 174, 204, 214, 244, 254, 284
y2 = [0, 1, 2,  3,  4,  3,  4,   3,   4,   3] #  4,   3,   4,   3,   4,   3 

x3 = [2, 3, 10, 26, 58, 88, 102, 132, 142, 172] # 182, 212, 222, 252, 262, 292]
y3 = [0, 1, 2,  3,  4,  3,  4,   3,   4,   3] #   4,   3,   4,   3,   4,   3] 

x4 = [3, 4, 12, 30, 66, 96, 110, 140, 150, 180] # 190, 220, 230, 260, 270, 300]
y4 = [0, 1, 2,  3,  4,  3,  4,   3,   4,   3] #   4,   3,   4,   3,   4,   3] 

x5 = [4, 5, 14, 34, 64, 70, 78, 108, 118, 148] # 158, 188, 198, 228, 238, 268, 278, 308]
y5 = [0, 1, 2,  3,  2,  3,  4,   3,   4,   3] #   4,   3,   4,   3,   4,   3,   4,  3] 

plt.step(x1, y1, where='post')
plt.step(x2, y2, where='post')
plt.step(x3, y3, where='post')
plt.step(x4, y4, where='post')
plt.step(x5, y5, where='post')
plt.xlabel("ticks")
plt.ylabel("Queue No.")
plt.text(120, 0.5, r'Aging Time: 30 sec', fontsize=10)

plt.show()  # display