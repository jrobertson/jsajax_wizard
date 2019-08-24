#!/usr/bin/env ruby

# file: jsajax_wizard.rb

# description: Makes building an AJAX web page easier than 
#              copying and pasting an example.
# examples:
#
# jaw = JsAjaxWizard.new
#
#
# AJAX triggered from a button press
# jaw.add_request server: 'hello', element: {type: 'button', 
#         event: 'onclick'}, target_element: {id: 'demo', property: :innerHTML}
#
# AJAX triggered from an onkeyup event
# jaw.add_request server: 'hello', element: {type: 'text'}, 
#         target_element: {id: 'demo', property: :innerHTML}
#
# AJAX triggered from a timer event
# jaw.add_request server: 'hello', element: {type: 'timer', 
#         interval: '5000'}, target_element: {id: 'demo', property: :innerHTML}



require 'rexle'
require 'rexle-builder'

class JsAjaxWizard
  using ColouredText

  def initialize(html='', debug: false)

    @html, @debug = html, debug
    @requests = []

  end

  def add_request(server: '', element: {}, target_element: {})
    @requests << [server, element, target_element]
  end

  def to_html()
    
    html = @html.empty? ? build_html : @html
    
    puts 'html: ' + html.inspect if @debug
    
    doc = Rexle.new(html)
    puts 'doc.xml: ' + doc.xml(pretty: true) if @debug
    add_events(doc)
    doc.root.element('body').add(Rexle.new(build_js))    
    
    doc.xml    
  end

  private
  
  def add_events(doc)    
    
    @requests.each.with_index do |x,i|
      
      element  = x[1]
      
      selector = if element[:id] then
        '#' + element[:id]
      elsif element[:type]
        "*[type=%s]" % element[:type]
      end
      
      if @debug then
        puts "selector: *|%s|*" % selector.inspect 
        puts 'doc: ' + doc.xml(pretty: true).inspect
      end
      
      e = doc.at_css(selector)
      next unless e
      puts ('e: ' + e.inspect).debug if @debug
      
      func = 'ajaxCall' + (i+1).to_s
      event = e.attributes[:type] == 'button' ? func + '()' : func + '(this)'
      
      puts ('element: ' + element.inspect).debug if @debug
      
      key = if element[:event] then
      
        if element[:event].to_sym == :on_enter then
          event = func + '(event.keyCode, this)'
          :onkeyup
        else
          element[:event].to_sym
        end
        
      else
        e.attributes[:type] == 'button' ? :onclick : :onkeyup
      end
      
      e.attributes[key] = event
      
    end
    
    doc
  end

  def build_elements()

    html = @requests.map.with_index do |x,i|

      e, e2 = x[1..-1]
      
      # e = element e.g. {type: 'button', event: 'onclick'} 
      # e2 = target_element: {id: '', property: :innerHTML}

      a = if e[:type].to_s == 'button' then
      
        ["<button type='button''>Change Content</button>"]
        
      elsif e[:type].to_s == 'text' then
        
        ["<input type='text'/>"]
        
      else
        ['']
      end

      a << "<div id='%s'></div>" % [e2[:id]]
      a.join("\n")

    end

    r = html.join("\n")
    puts 'r: ' + r.inspect if @debug
    r

  end
  
  def build_html()

    RexleBuilder.build do |xml|
      xml.html do 
        xml.head do
          xml.meta name: "viewport", content: \
              "width=device-width, initial-scale=1"
          xml.style "\nbody {font-family: Arial;}\n\n"
        end
        xml.body build_elements
      end
    end
    
  end

  def build_js()

    func_calls = @requests.length.times.map do |i|
      "// ajaxCall#{i+1}();"
    end

ajax=<<EOF
function ajaxRequest(url, cFunction) {
  var xhttp;
  xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      cFunction(this);
    }
  };
  xhttp.open("GET", url, true);
  xhttp.send();
}
EOF

    funcs_defined = @requests.map.with_index do |x,i|
      
      a = []
      server, element, target_element = x
      
      a << if element[:type] == 'text' then
      
        if element[:event].to_sym == :on_enter then
        "
function ajaxCall#{i+1}(keyCode, e) {
  
  if (keyCode==13){
    ajaxRequest('#{server}' + e.value, ajaxResponse#{i+1})
  }  
  
}
"
        else
        "
function ajaxCall#{i+1}(e) {
  ajaxRequest('#{server}' + e.value, ajaxResponse#{i+1})
}
"
        end
        
      elsif element[:type] == 'timer'
        "
setInterval(
  function() {
    ajaxRequest('#{server}', ajaxResponse#{i+1})
  }, #{element[:interval]});
"        
      else
"
function ajaxCall#{i+1}() {
  ajaxRequest('#{server}', ajaxResponse#{i+1})
}
"
      end

a << "
function ajaxResponse#{i+1}(xhttp) {
  document.getElementById('#{target_element[:id]}').innerHTML = xhttp.responseText;
}
"

      a.join
    end

    s = func_calls.join("\n") + "\n\n" + ajax + "\n\n" + funcs_defined.join
    "\n  <script>\n%s\n  </script>\n" % s

  end

end
