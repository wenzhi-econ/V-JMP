import numpy as np

linear_term_tenure_regression = 0.02215986
squared_term_tenure_regression = -0.00045828
effect_7yrslater = 0.13526208

coefficients = [
    squared_term_tenure_regression,
    linear_term_tenure_regression,
    -effect_7yrslater,
]
roots = np.roots(coefficients)
print(f"The roots are: {roots}")
