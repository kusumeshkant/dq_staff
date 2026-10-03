abstract class AppRoutes {
  // ── Auth flow ───────────────────────────────────────────────────────────────
  static const login    = '/login';
  static const register = '/register';
  static const invite   = '/invite';

  // ── Main ────────────────────────────────────────────────────────────────────
  static const home     = '/home';

  // ── In-session push routes ──────────────────────────────────────────────────
  static const orders          = '/orders';
  static const completedOrders = '/orders/completed';
  static const failedOrders    = '/orders/failed';
  static const myOrders        = '/orders/my';
  static const orderDetail     = '/orders/detail';
  static const products        = '/products';
  static const addProduct      = '/products/add';
  static const scanner         = '/scanner';
  static const exitValidation  = '/exit-validation';
  static const access          = '/access';
}
