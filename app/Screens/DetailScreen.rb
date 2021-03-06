class DetailScreen < SizeableWebScreen
  attr_accessor :style, :cell, :search_string

  def on_load

    if Device.ipad?
      set_nav_bar_right_button UIImage.imageNamed("info.png"), action: :open_about_screen

      view.when_swiped do |swipe|
        App.delegate.main_screen.next
      end.direction = UISwipeGestureRecognizerDirectionLeft

      view.when_swiped do |swipe|
        App.delegate.main_screen.previous
      end.direction = UISwipeGestureRecognizerDirectionRight
    end
  end

  def will_appear
    if defined? style.id
      self.setTitle the_title(false)
      set_attributes web, {background_color:UIColor.whiteColor}
    else
      self.setTitle "Welcome".__
      set_attributes web, {background_color:"#CCCC99".to_color}
    end
  end

  def on_appear
    return unless defined? style.id
    super

    flurry_params = {style: the_title}
    Flurry.logEvent("StyleViewed", withParameters:flurry_params) unless Device.simulator?
  end

  def the_title(with_subtitle = true)
    return "" unless defined? style.id
    t = "#{style.category}#{style.id.as_letter}: #{style.name}"
    if with_subtitle
      t << "<br /><small>(#{style.transname})<small>" unless style.transname.nil? || style.transname.empty?
    end
    t
  end

  def load_finished
    super
    set_srm_range
  end

  def content
    return Internationalization.resources_path("DefaultScreen.html") if self.style.nil?

    <<-CONTENT

#{css}
#{js}

<div class="srmrange">&nbsp;</div>
<h1>#{the_title}</h1>
<div class="srmrange">&nbsp;</div>

#{style.html(:aroma)}
#{style.html(:appearance)}
#{style.html(:flavor)}
#{style.html(:mouthfeel)}
#{style.html(:impression)}
#{style.html(:comments)}
#{style.html(:history)}
#{style.html(:ingredients)}
#{style.html(:specs)}
#{style.html(:examples)}

#{search_js}
    CONTENT
  end

  def css
    "<style>" << File.read(File.join(App.resources_path, "style.css")) << "</style>"
  end

  def js
    return "" if self.search_string.nil?
    "<script>" << File.read(File.join(App.resources_path, "highlighter.js")) << "</script>"
  end

  def search_js
    return "" if self.search_string.nil?
    "<script>" << "$('p').highlight('" << self.search_string << "')" << "</script>"
  end

  def set_srm_range
    if style.nil? || style.srm_range.nil?
      gradient = "display:none;"
    else
      gradient = SRM.css_gradient(style.srm_range) unless style.nil?
    end
    evaluate "document.body.innerHTML += '<style>.srmrange{#{gradient}}</style>'"
  end

end
