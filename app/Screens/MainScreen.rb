class MainScreen < ProMotion::SectionedTableScreen
  title "2008 BJCP Styles"
  searchable :placeholder => "Search Styles"

  def will_appear
    @view_set_up ||= begin
      set_attributes self.view, { backgroundColor: UIColor.whiteColor }

      unless Device.ipad?
        set_nav_bar_right_button UIImage.imageNamed("info.png"), action: :open_info_screen
      end

      backBarButtonItem = UIBarButtonItem.alloc.initWithTitle("Back", style:UIBarButtonItemStyleBordered, target:nil, action:nil)
      self.navigationItem.backBarButtonItem = backBarButtonItem;

      read_xml
    end
  end

  def on_appear
    toolbar_animated = Device.ipad? ? false : true
    self.navigationController.setToolbarHidden(true, animated:toolbar_animated)
  end

  def table_data
    @table_setup ||= begin
      s = []

      sections.each do |section|
        s << {
          title: section_title(section),
          cells: build_subcategories(section["subcategory"])
        }
      end
      s
    end
  end

  def build_subcategories(params)
    c = []

    # Support categories with only one subcategory
    params = [params] if params.is_a?(Hash)
    params.each do |subcat|
      c << {
        title: subcategory_title(subcat),
        search_text: subcategory_search_text(subcat),
        cell_identifier: "SubcategoryCell",
        action: :open_style,
        arguments: {:data => subcat}
      }
    end
    c
  end

  def table_data_index
    # Get the style number of the section
    ["{search}"] + table_data.collect do |section|
      section[:title].split(" ").first[0..-2]
    end
  end

  def open_style(args={})
    ap args
    # self.navigationItem.title = "Back"
    if Device.ipad?
      open DetailScreen.new(args), nav_bar:true, in_detail: true
    else
      open DetailScreen.new(args)
    end
  end

  def open_info_screen(args={})
    open_modal AboutScreen.new(external_links: true),
      nav_bar: true,
      presentation_style: UIModalPresentationFormSheet
  end

  def beer_categories
    overall_category "beer"
  end

  def mead_categories
    overall_category "mead"
  end

  def cider_categories
    overall_category "cider"
  end

  def sections
    return [] if @styles.nil?
    # ["Beer"] + beer_categories + ["Mead"] + mead_categories + ["Cider"] + cider_categories
    beer_categories + mead_categories + cider_categories
  end

  def section_title(section)
    "#{section['id']}: #{section["name"]}"
  end

  def subcategory_title(subcat)
    "#{subcat['id']}: #{subcat['name']}"
  end

  def subcategory_search_text(subcat)
    search = ""
    %w(impression appearance ingredients examples aroma mouthfeel flavor).each do |prop|
      search << (" " + subcat[prop]) unless subcat[prop].nil?
    end
    search.split(/\W+/).uniq.join(" ")
  end

  private

  # Return the subsection of the Hash object for a particular class of styles.
  # beer, mead, & cider are the current classes.
  def overall_category(name)
    this_class = @styles["styleguide"]["class"].select{|classes| classes["type"] == name }
    this_class.first["category"]
  end

  def read_xml
    @done_read_xml ||= begin
      style_path = File.join(App.resources_path, "styleguide2008.xml")
      styles = File.read(style_path).gsub("<em>", "[em]").gsub("</em>", "[/em]")

      error_ptr = Pointer.new(:object)
      style_hash = TBXML.dictionaryWithXMLData(styles.dataUsingEncoding(NSUTF8StringEncoding), error: error_ptr)
      error = error_ptr[0]
      $stderr.puts "Error when reading data: #{error}. Did you run 'rake bootstrap'?" unless error.nil?

      @styles = style_hash
      @table_setup = nil
      update_table_data
    end
  end

end
