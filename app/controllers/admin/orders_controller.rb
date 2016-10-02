class Admin::OrdersController < Admin::AdminBaseController

  before_action :find_order, only: [:edit, :update]

  def index
    # PaperTrail::Version.all
    @orders = Order.includes(:items).references(:items).all.page(params[:page]).per(50).order("orders.id desc")
  end

  def new
    @order = Order.new
  end

  def create
    @order = Order.new order_params
    if @order.valid?
      @order.save
      redirect_to edit_admin_order_path @order
    else
      render :new
    end
  end

  def edit

  end

  def update
    @order.attributes = order_params
    if @order.valid?
      @order.save
      redirect_to action: :index
    else
      render :edit
    end
  end

  # 下载pdf
  def download_pdf
    html = ''
    file_name = UUIDTools::UUID.random_create
    order = Order.first
    # html = get_context(params, article) if article.present?
    html = get_context order
    if html.blank?
      flash[:notice] = "データが存在しません。"
      return redirect_to orders_path
    end
    pdf = PdfUtil.config(html, 'page')
    pdf.to_file("order", "#{file_name}.pdf")
    path = "#{Rails.root.to_s}/tmp/pdf/order/#{file_name}.pdf" rescue nil
    if path.blank?
      flash[:notice] = t('no_data')
      return redirect_to orders_path unless path
    end
    send_file(path, filename: encode_file_name("glass_list.pdf"))
  end

  # def to_pdf
  #   # 1 生成pdf文件 （指定模板）
  #   make_pdf template: "admin/events/to_pdf2.html.erb", filepath: File.join("#{Rails.root.to_s}/tmp/pdf/", "to_pdf2.pdf")
  #   # 2 生成pdf文件 （不指定模板，默认当前action对应的模板）
  #   make_pdf filepath: File.join("#{Rails.root.to_s}/tmp/pdf/", "to_pdf.pdf")
  #   # 3,直接推送
  #   make_and_send_pdf "send_pdf.pdf", template: "admin/events/to_pdf2.html.erb"
  # end

  # def undo_link
    # view_context.link_to("undo", revert_version_path(@product.versions.scoped.last), :method => :post)
  # end

  private

  def find_order
    @order = Order.find_by_id(params[:id])
    @items = @order.items
    if @order.blank?
      flash[:error] = t('no_data')
      redirect_to action: :index
    end
  end

  def order_params
    params.fetch(:order, {}).permit(:name, :code);
  end

  # 获取模板以及将模板中需要动态显示数据的地方，把数据获取到
  def get_context order
    template = get_template
    return order.context!(template)
  end

  # 获取模板
  def get_template
    template = ''
    tmp = File.new("#{Rails.root.to_s}/public/files/glass_list1.html").read
    template += tmp
    template
  end

end
