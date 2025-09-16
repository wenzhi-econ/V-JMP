#! python3
"""
This file calculates the tenure equivalent of the effects of a high-flyer manager on total salary.
Notes:
    The coefficients are calculated in "StatInPaper03_01_PayEffectsMagnitudes.do".
    This file simply calculates the root reported in the paper.

RA: WWZ
Time: 2025-08-07
"""

import numpy as np

linear_term_tenure_regression = 0.0224455
squared_term_tenure_regression = -0.00046742
effect_7yrslater = 0.13521613

coefficients = [
    squared_term_tenure_regression,
    linear_term_tenure_regression,
    -effect_7yrslater,
]
roots = np.roots(coefficients)
print(f"The roots are: {roots}")
