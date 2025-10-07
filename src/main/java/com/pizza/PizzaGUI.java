package com.pizza;

import javax.swing.*;
import javax.swing.border.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.math.BigDecimal;
import java.sql.*;
import java.util.UUID;

import com.formdev.flatlaf.FlatLightLaf;
import com.formdev.flatlaf.util.UIScale;

public class CreamBurgundyPizzaUI extends JFrame {

    private final String sessionId = "cli-session-" + UUID.randomUUID().toString().substring(0, 8);

    private final DefaultTableModel menuModel = new DefaultTableModel(new Object[]{"ID", "Name", "Category", "Price"}, 0) {
        public boolean isCellEditable(int r, int c) { return false; }
    };
    private final DefaultTableModel cartModel = new DefaultTableModel(new Object[]{"ID", "Name", "Quantity", "Price", "Together"}, 0) {
        public boolean isCellEditable(int r, int c) { return false; }
    };

    private final JTable menuTable = new JTable(menuModel);
    private final JTable cartTable = new JTable(cartModel);
    private final JSpinner qtySpinner = new JSpinner(new SpinnerNumberModel(1, 1, 99, 1));
    private final JTextField customerField = new JTextField("1", 8);
    private final JTextField discountField = new JTextField("", 12);
    private final JLabel totalLabel = new JLabel("Sum: 0.00");

    private static final Color CREAM          = Color.decode("#FAEBD7");
    private static final Color CREAM2         = Color.decode("#FFF6EA");
    private static final Color BURGUNDY       = Color.decode("#7B1F1F");
    private static final Color BURGUNDY_DARK  = Color.decode("#611717");

    public CreamBurgundyPizzaUI() {
        super("Database Pizzeria!");
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(1040, 620);
        setLocationRelativeTo(null);
        getContentPane().setBackground(CREAM);

        JLabel banner = new JLabel("Database Pizzeria!", SwingConstants.CENTER);
        banner.setFont(banner.getFont().deriveFont(Font.BOLD, UIScale.scale(22)));
        banner.setForeground(BURGUNDY);
        JPanel bannerWrap = new JPanel(new BorderLayout());
        bannerWrap.setBackground(CREAM);
        bannerWrap.setBorder(new MatteBorder(0, 0, 2, 0, BURGUNDY));
        bannerWrap.add(banner, BorderLayout.CENTER);

        JPanel top = new JPanel(new GridBagLayout());
        top.setBackground(CREAM);
        top.setBorder(new EmptyBorder(8, 12, 8, 12));
        GridBagConstraints gc = new GridBagConstraints();
        gc.insets = new Insets(0, 6, 0, 6);
        gc.gridy = 0;
        gc.fill = GridBagConstraints.HORIZONTAL;

        customerField.setEditable(true);
        customerField.setEnabled(true);
        customerField.setFocusable(true);
        discountField.setEditable(true);
        discountField.setEnabled(true);
        discountField.setFocusable(true);

        styleField(customerField);
        styleField(discountField);
        ((JComponent) qtySpinner.getEditor()).setBackground(CREAM2);

        JButton refreshBtn = themedButton("Refresh menu");
        JButton addBtn     = themedButton("Add to the cart");
        JButton removeBtn  = themedButton("Remove from the cart");
        JButton clearBtn   = themedButton("Clear cart");
        JButton orderBtn   = themedButton("Make order");

        int col = 0;
        gc.weightx = 0;     gc.gridx = col++; top.add(new JLabel("CustomerID:"), gc);
        gc.weightx = 0.18;  gc.gridx = col++; top.add(customerField, gc);
        gc.weightx = 0;     gc.gridx = col++; top.add(new JLabel("Discount Code:"), gc);
        gc.weightx = 0.25;  gc.gridx = col++; top.add(discountField, gc);
        gc.weightx = 0;     gc.gridx = col++; top.add(new JLabel("Quantity:"), gc);
        gc.weightx = 0.10;  gc.gridx = col++; top.add(qtySpinner, gc);
        gc.weightx = 0;     gc.gridx = col++; top.add(refreshBtn, gc);
        gc.gridx = col++; top.add(addBtn, gc);
        gc.gridx = col++; top.add(removeBtn, gc);
        gc.gridx = col++; top.add(clearBtn, gc);
        gc.gridx = col++; top.add(orderBtn, gc);

        styleTable(menuTable);
        styleTable(cartTable);
        JPanel left  = section("MENU", new JScrollPane(menuTable));
        JPanel right = sectionWithTotal("CART", new JScrollPane(cartTable), totalLabel);

        JSplitPane split = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, left, right);
        split.setBorder(new MatteBorder(0, 0, 0, 0, CREAM));
        split.setBackground(CREAM);
        split.setDividerLocation(540);
        split.setResizeWeight(0.55);

        JPanel north = new JPanel(new BorderLayout());
        north.setBackground(CREAM);
        north.add(bannerWrap, BorderLayout.NORTH);
        north.add(top, BorderLayout.CENTER);

        JPanel centerWrap = new JPanel(new BorderLayout());
        centerWrap.setBackground(CREAM);
        centerWrap.setBorder(new EmptyBorder(10, 10, 10, 10));
        centerWrap.add(split, BorderLayout.CENTER);

        getContentPane().setLayout(new BorderLayout());
        getContentPane().add(north, BorderLayout.NORTH);
        getContentPane().add(centerWrap, BorderLayout.CENTER);

        refreshBtn.addActionListener(e -> loadMenu());
        addBtn.addActionListener(e -> addToCart());
        removeBtn.addActionListener(e -> removeFromCart());
        clearBtn.addActionListener(e -> clearCart());
        orderBtn.addActionListener(e -> placeOrder());

        loadMenu();
        refreshCart();
    }

    private JButton themedButton(String text) {
        JButton b = new JButton(text);
        b.setFocusPainted(false);
        b.setBackground(CREAM2);
        b.setForeground(BURGUNDY);
        b.setBorder(new CompoundBorder(new LineBorder(BURGUNDY, 2, true), new EmptyBorder(6, 12, 6, 12)));
        b.addChangeListener(e -> {
            if (b.getModel().isRollover())
                b.setBorder(new CompoundBorder(new LineBorder(BURGUNDY_DARK, 2, true), new EmptyBorder(6, 12, 6, 12)));
            else
                b.setBorder(new CompoundBorder(new LineBorder(BURGUNDY, 2, true), new EmptyBorder(6, 12, 6, 12)));
        });
        return b;
    }

    private void styleField(JTextField f) {
        f.setBackground(CREAM2);
        f.setBorder(new CompoundBorder(new LineBorder(BURGUNDY, 1, true), new EmptyBorder(4, 6, 4, 6)));
    }

    private void styleTable(JTable t) {
        t.setRowHeight(24);
        t.setShowHorizontalLines(true);
        t.setShowVerticalLines(false);
        t.setGridColor(new Color(0, 0, 0, 20));
        t.getTableHeader().setBackground(CREAM);
        t.getTableHeader().setForeground(BURGUNDY);
        t.getTableHeader().setFont(t.getTableHeader().getFont().deriveFont(Font.BOLD));
        t.setBackground(Color.WHITE);
        t.setSelectionBackground(new Color(255, 230, 224));
        t.setSelectionForeground(Color.BLACK);
    }

    private JPanel section(String title, JComponent center) {
        JPanel p = new JPanel(new BorderLayout());
        p.setBackground(CREAM);
        p.setBorder(new CompoundBorder(new MatteBorder(2, 2, 2, 2, BURGUNDY), new EmptyBorder(8, 8, 8, 8)));
        JLabel h = new JLabel(title);
        h.setFont(h.getFont().deriveFont(Font.BOLD, 14f));
        h.setForeground(BURGUNDY);
        p.add(h, BorderLayout.NORTH);
        p.add(center, BorderLayout.CENTER);
        return p;
    }

    private JPanel sectionWithTotal(String title, JComponent center, JLabel total) {
        JPanel p = section(title, center);
        JPanel south = new JPanel(new BorderLayout());
        south.setBackground(CREAM);
        south.setBorder(new EmptyBorder(8, 0, 0, 0));
        total.setFont(total.getFont().deriveFont(Font.BOLD));
        total.setForeground(BURGUNDY);
        south.add(total, BorderLayout.EAST);
        p.add(south, BorderLayout.SOUTH);
        return p;
    }

    private Connection conn() throws SQLException {
        return DB.get();
    }

    private void loadMenu() {
        menuModel.setRowCount(0);
        String sql =
                "SELECT menu_item_id, name, category, price " +
                        "FROM v_menu_final_prices ORDER BY category, name";
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                menuModel.addRow(new Object[]{rs.getInt(1), rs.getString(2), rs.getString(3), rs.getBigDecimal(4)});
            }
        } catch (Exception ex) {
            error("Error load menu: " + ex.getMessage());
        }
    }

    private void refreshCart() {
        cartModel.setRowCount(0);
        String sql = """
            SELECT ci.menu_item_id, mi.name, ci.qty, v.price, (ci.qty * v.price) AS line_total
            FROM cart_item ci
            JOIN menu_item mi ON mi.menu_item_id = ci.menu_item_id
            JOIN v_menu_final_prices v ON v.menu_item_id = mi.menu_item_id
            WHERE ci.session_id = ?
            ORDER BY mi.category, mi.name
            """;
        BigDecimal sum = BigDecimal.ZERO;
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, sessionId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Object[] row = new Object[]{
                            rs.getInt(1), rs.getString(2), rs.getInt(3),
                            rs.getBigDecimal(4), rs.getBigDecimal(5)
                    };
                    cartModel.addRow(row);
                    sum = sum.add(rs.getBigDecimal(5));
                }
            }
        } catch (Exception ex) {
            error("Error check cart: " + ex.getMessage());
        }
        totalLabel.setText("Sum: " + sum);
    }

    private void addToCart() {
        int row = menuTable.getSelectedRow();
        if (row < 0) { info("Choose from menu."); return; }
        int menuId = (int) menuModel.getValueAt(row, 0);
        int qty = (Integer) qtySpinner.getValue();

        String upsert = """
            INSERT INTO cart_item(session_id, menu_item_id, qty)
            VALUES(?, ?, ?)
            ON DUPLICATE KEY UPDATE qty = qty + VALUES(qty)
            """;
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement(upsert)) {
            ps.setString(1, sessionId);
            ps.setInt(2, menuId);
            ps.setInt(3, qty);
            ps.executeUpdate();
            refreshCart();
        } catch (Exception ex) {
            error("Error add to the cart: " + ex.getMessage());
        }
    }

    private void removeFromCart() {
        int row = cartTable.getSelectedRow();
        if (row < 0) { info("Select an item in the cart."); return; }
        int menuId = (int) cartModel.getValueAt(row, 0);

        String del = "DELETE FROM cart_item WHERE session_id=? AND menu_item_id=?";
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement(del)) {
            ps.setString(1, sessionId);
            ps.setInt(2, menuId);
            ps.executeUpdate();
            refreshCart();
        } catch (Exception ex) {
            error("Error delete from cart: " + ex.getMessage());
        }
    }

    private void clearCart() {
        String del = "DELETE FROM cart_item WHERE session_id=?";
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement(del)) {
            ps.setString(1, sessionId);
            ps.executeUpdate();
            refreshCart();
        } catch (Exception ex) {
            error("Error clear cart: " + ex.getMessage());
        }
    }

    private void placeOrder() {
        int customerId;
        try {
            customerId = Integer.parseInt(customerField.getText().trim());
        } catch (NumberFormatException nfe) {
            error("CustomerID must be a number.");
            return;
        }
        if (cartModel.getRowCount() == 0) {
            info("Cart is empty.");
            return;
        }
        String code = discountField.getText().trim();

        String call = "{ call place_order(?, ?, ?) }";
        try (Connection c = conn(); CallableStatement cs = c.prepareCall(call)) {
            cs.setString(1, sessionId);
            cs.setInt(2, customerId);
            if (code.isEmpty()) cs.setNull(3, Types.VARCHAR); else cs.setString(3, code);
            cs.execute();

            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT order_id, grand_total FROM `order` WHERE customer_id=? ORDER BY order_id DESC LIMIT 1")) {
                ps.setInt(1, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        info("Order #" + rs.getLong(1) + " made. To be paid: " + rs.getBigDecimal(2));
                    } else {
                        info("Order made.");
                    }
                }
            }
            clearCart();
        } catch (Exception ex) {
            error("Issue while making order: " + ex.getMessage());
        }
    }

    private void info(String m)  { JOptionPane.showMessageDialog(this, m, "Info", JOptionPane.INFORMATION_MESSAGE); }
    private void error(String m) { JOptionPane.showMessageDialog(this, m, "Error", JOptionPane.ERROR_MESSAGE); }

    public static void main(String[] args) {
        try {
            FlatLightLaf.setup();
            UIManager.put("Panel.background", CREAM);
            UIManager.put("Table.background", Color.WHITE);
            UIManager.put("ScrollPane.background", CREAM);
            UIManager.put("SplitPane.background", CREAM);
        } catch (Exception ignore) {}

        SwingUtilities.invokeLater(() -> new CreamBurgundyPizzaUI().setVisible(true));
    }
}
