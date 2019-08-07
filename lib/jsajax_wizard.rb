#!/usr/bin/env ruby

# file: jsajax_wizard.rb

# description: Makes building an AJAX web page easier than 
#              copying and pasting an example.

require 'rexle'
require 'rexle-builder'

class JsAjaxWizard

  def initialize(html: '', debug: false)

    @debug = debug
    @requests = []

  end

  def add_request(server: '', element: {}, target_element: {})
    @requests << [server, element, target_element]
  end

  def to_html()

    a = RexleBuilder.build do |xml|
      xml.html do 
        xml.head do
          xml.meta name: "viewport", content: \
              "width=device-width, initial-scale=1"
          xml.style "\nbody {font-family: Arial;}\n\n"
        end
        xml.body build_html + "\n" + build_js()
      end
    end

    doc = Rexle.new(a)
    
  end

  private

  def build_html()

    html = @requests.map.with_index do |x,i|

      e, e2 = x[1..-1]
      
      # e = element e.g. {type: 'button', event: 'onclick'} 
      # e2 = target_element: {id: '', property: :innerHTML}

      a = if e[:type] == 'button' then
        ["<button type='button' %s='ajaxCall%s()'>Change Content</button>" \
          % [e[:event], i+1]]
      else
        ''
      end

      a << "<div id='%s'></div>" % [e2[:id]]
      a.join("\n")

    end

    html.join("\n")

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

      server, element, target_element = x
"
function ajaxCall#{i+1}() {
  ajaxRequest('#{server}', ajaxResponse#{i+1})
}

function ajaxResponse#{i+1}(xhttp) {
  document.getElementById('#{target_element[:id]}').innerHTML = xhttp.responseText;
}
" 
    end

    s = func_calls.join("\n") + "\n\n" + ajax + "\n\n" + funcs_defined.join
    "\n  <script>\n%s\n  </script>\n" % s

  end

end
