import '../permissions/role_model.dart';
import 'nav_menu_item.dart';
import 'employee_menu.dart';
import 'tl_menu.dart';
import 'hr_menu.dart';
import 'admin_menu.dart';

class RoleMenuBuilder {
  static List<NavMenuItem> getMenuForRole({
    required AppRole role,
    int pendingApprovals = 0,
    int pendingNotifs = 0,
  }) {
    switch (role) {
      case AppRole.employee:
        return EmployeeMenu.getMenuItems(pendingNotifs: pendingNotifs);
      case AppRole.tl:
        return TLMenu.getMenuItems(
          pendingApprovalsCount: pendingApprovals,
          pendingNotifs: pendingNotifs,
        );
      case AppRole.hr:
        return HRMenu.getMenuItems(pendingNotifs: pendingNotifs);
      case AppRole.admin:
        return AdminMenu.getMenuItems(
          pendingApprovals: pendingApprovals,
          pendingNotifs: pendingNotifs,
        );
    }
  }
}
