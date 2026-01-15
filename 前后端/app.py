from flask import Flask, render_template, request, redirect, url_for, session, flash
import pymysql

app = Flask(__name__)
app.secret_key = 'super_secret_key'  # 随便填，用于加密 session

# === 数据库连接配置 ===
def get_db_connection():
    return pymysql.connect(
        host='localhost',
        user='root',
        password='919303',    
        database='campus_ordering',
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True       # 开启自动提交，防止数据写不进去
    )

# === 1. 登录页面 ===
@app.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # 登录时顺便查出店铺ID（如果是商家），方便后面筛选订单
        sql = """
            SELECT u.*, s.shop_id, s.shop_name 
            FROM sys_users u 
            LEFT JOIN shops s ON u.user_id = s.owner_id
            WHERE u.username = %s AND u.password = %s
        """
        cursor.execute(sql, (username, password))
        user = cursor.fetchone()
        conn.close()

        if user:
            session['user_id'] = user['user_id']
            session['role'] = user['role']
            session['nickname'] = user['nickname'] or user['username']
            session['address'] = user['address']
            # 如果是商家，存一下他的店铺ID
            if user['shop_id']:
                session['shop_id'] = user['shop_id']
                session['shop_name'] = user['shop_name']
            return redirect(url_for('dashboard'))
        else:
            flash('账号或密码错误')
            
    return render_template('login.html')

# === 2. 核心控制台 (根据角色分流) ===
# === 2. 核心控制台 (根据角色分流) ===
@app.route('/dashboard')
def dashboard():
    # 1. 如果没登录，踢回去
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    role = session['role']
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # --- 场景A: 消费者 (只查店铺) ---
    if role == 'consumer':
        cursor.execute("SELECT * FROM shops WHERE status=1")
        shops = cursor.fetchall()
        conn.close()
        return render_template('consumer_dashboard.html', shops=shops, name=session['nickname'])

    # --- 场景B: 商家 (看自家订单) ---
    elif role == 'merchant':
        shop_id = session.get('shop_id')
        # 查所有属于我店铺的订单 (通过视图 v_order_details)
        cursor.execute("SELECT * FROM v_order_details WHERE shop_name = %s ORDER BY create_time DESC", (session.get('shop_name'),))
        orders = cursor.fetchall()
        conn.close()
        return render_template('merchant_dashboard.html', orders=orders, name=session['nickname'])

    # --- 场景C: 配送员 (看待接单 + 配送中的单) ---
    elif role == 'courier':
        # 查 "待发货(0)" 或 "我正在送/已送完" 的单
        sql = "SELECT * FROM v_order_details WHERE status = 0 OR courier_id = %s ORDER BY create_time DESC"
        cursor.execute(sql, (session['user_id'],))
        orders = cursor.fetchall()
        conn.close()
        return render_template('courier_dashboard.html', orders=orders, name=session['nickname'])
    
    # --- 兜底逻辑：防止未知角色报错 ---
    else:
        conn.close()
        return "错误：未知的用户角色"
# === 新增功能：进入店铺详情页 ===
@app.route('/shop/<int:shop_id>')
def view_shop(shop_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # 1. 查这家店的基本信息 (店名、地址等)
    cursor.execute("SELECT * FROM shops WHERE shop_id = %s", (shop_id,))
    shop = cursor.fetchone()
    
    # 2. 查这家店的所有上架菜品
    # 注意：这里不再需要 JOIN shops 表，因为我们已经知道是哪家店了
    cursor.execute("SELECT * FROM dishes WHERE shop_id = %s AND is_available=1", (shop_id,))
    dishes = cursor.fetchall()
    
    conn.close()
    
    # 渲染一个新的模板 shop_details.html
    return render_template('shop_details.html', shop=shop, dishes=dishes, name=session['nickname'])

# === 新增功能：订单管理页面 (支持筛选) ===
@app.route('/my_orders')
@app.route('/my_orders/<status_type>')
def my_orders(status_type='all'):
    if 'user_id' not in session: return redirect(url_for('login'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # 基础 SQL
    sql = "SELECT * FROM v_order_details WHERE user_id = %s"
    params = [session['user_id']]
    
    # 根据点击的按钮筛选
    if status_type == 'unshipped':  # 未接单/未发货
        sql += " AND status = 0"
        title = "未接单订单"
    elif status_type == 'delivering': # 配送中
        sql += " AND status = 1"
        title = "配送中订单"
    elif status_type == 'completed': # 已完成
        sql += " AND status = 2"
        title = "已完成订单"
    else:
        title = "全部订单" # 默认显示所有
        
    sql += " ORDER BY create_time DESC"
    
    cursor.execute(sql, params)
    orders = cursor.fetchall()
    conn.close()
    
    return render_template('consumer_orders.html', orders=orders, title=title, active_tag=status_type, name=session['nickname'])

# === 3. 功能：消费者下单 ===
@app.route('/buy/<int:dish_id>/<float:price>/<int:shop_id>')
def buy(dish_id, price, shop_id):
    if 'user_id' not in session: return redirect(url_for('login'))
    
    user_id = session['user_id']
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # 1. 获取当前用户的地址（如果没填地址，就显示'无地址'）
        current_address = session.get('address', '无地址') 

        # 2. 创建订单主表 (Order)
        cursor.execute(
            "INSERT INTO orders (user_id, shop_id, total_amount, address_snapshot, status) VALUES (%s, %s, %s, %s, 0)",
            (user_id, shop_id, price, current_address) # <--- 这里换成了变量！
        )
        new_order_id = conn.insert_id() # 获取刚才生成的订单ID
        
        # 3. 创建订单详情 (Order Item)
        # 这一步会触发你的 trigger (自动加销量，自动减库存)
        cursor.execute(
            "INSERT INTO order_items (order_id, dish_id, quantity, price_snapshot) VALUES (%s, %s, 1, %s)",
            (new_order_id, dish_id, price)
        )
        flash('下单成功！美味马上就到！')
    except Exception as e:
        print(e)
        flash('下单失败，请检查系统')
    finally:
        conn.close()
        
    return redirect(url_for('dashboard'))

# === 4. 功能：更新订单状态 (商家发货 / 骑手接单 / 确认送达 / 取消) ===
@app.route('/update_order/<int:order_id>/<int:new_status>')
def update_order(order_id, new_status):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # 如果是骑手接单 (状态变1)，需要把 courier_id 更新成当前用户
    if new_status == 1 and session['role'] == 'courier':
        cursor.execute("UPDATE orders SET status=1, courier_id=%s WHERE order_id=%s", (session['user_id'], order_id))
        
    # 如果是取消订单 (状态变4)，需要删除 order_items 来触发销量回滚 trigger
    elif new_status == 4:
        # 先删详情(触发回滚)，再改主表
        cursor.execute("DELETE FROM order_items WHERE order_id=%s", (order_id,))
        cursor.execute("UPDATE orders SET status=4 WHERE order_id=%s", (order_id,))
        
    # 其他普通状态变更 (如商家点发货，或骑手点送达)
    else:
        cursor.execute("UPDATE orders SET status=%s WHERE order_id=%s", (new_status, order_id))
        
    conn.close()
    return redirect(url_for('dashboard'))

# === 退出登录 ===
@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

if __name__ == '__main__':
    app.run(debug=True, port=5000)