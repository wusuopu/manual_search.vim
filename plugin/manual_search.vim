"=============================================================================
"
"     FileName: manual_search.vim
"         Desc: 开发文档搜索
"               需要先安装 w3m.vim
"
"       Author: LongChangjin
"        Email: admin@longchangjin.cn
"
"      Created: 2014-06-06
"
"=============================================================================

if !exists("g:php_manual_dir_path")
  " http://ar2.php.net/download-docs.php
  let g:php_manual_dir_path = $HOME . "/Book/Refernce/php/php-chunked-xhtml/"
endif

if !exists("g:php_symfony2_manual_dir_path")
  " http://symfony.com/doc/current/index.html
  let g:php_symfony2_manual_dir_path = $HOME . "/Book/Refernce/php/symfony-document/"
endif

if !exists("g:php_symfony2_api_manual_dir_path")
  " http://api.symfony.com/2.4/index.html
  let g:php_symfony2_api_manual_dir_path = $HOME . "/Book/Refernce/php/api.symfony.com/2.4/"
endif

if !exists("g:python2_manual_dir_path")
  " https://docs.python.org/2/
  let g:python2_manual_dir_path = $HOME . "/Book/Refernce/python-2.7.4-docs-html/"
endif

if !exists("g:python3_manual_dir_path")
  " https://docs.python.org/3/
  let g:python3_manual_dir_path = $HOME . "/Book/Refernce/python-3.3.3-docs-html/"
endif

if !exists("g:ruby_core_manual_dir_path")
  " http://www.ruby-doc.org/downloads/
  let g:ruby_core_manual_dir_path = $HOME . "/Book/Refernce/Ruby/ruby_2_1_1_core/"
endif

if !exists("g:ruby_stdlib_manual_dir_path")
  " http://www.ruby-doc.org/downloads/
  let g:ruby_stdlib_manual_dir_path = $HOME . "/Book/Refernce/Ruby/ruby_2_1_1_stdlib/"
endif

function! W3M_PHPManual()
  execute "W3mTab local " . g:php_manual_dir_path . "index.html"
endfunction

function! W3M_PHPSymfonyApi()
  execute "W3mTab local " . g:php_symfony2_api_manual_dir_path . "index.html"
endfunction

function! W3M_Python2Docs()
  execute "W3mTab local " . g:python2_manual_dir_path . "index.html"
endfunction

function! W3M_Python3Docs()
  execute "W3mTab local " . g:python3_manual_dir_path . "index.html"
endfunction

function! W3M_RubyCore()
  execute "W3mTab local " . g:ruby_core_manual_dir_path . "index.html"
endfunction

function! W3M_RubyStdlib()
  execute "W3mTab local " . g:ruby_stdlib_manual_dir_path . "index.html"
endfunction

command! -nargs=0 PHPManual :call W3M_PHPManual()
command! -nargs=0 PHPSymfonyApi :call W3M_PHPSymfonyApi()
command! -nargs=0 Python2Docs :call W3M_Python2Docs()
command! -nargs=0 Python3Docs :call W3M_Python3Docs()
command! -nargs=0 RubyCore :call W3M_RubyCore()
command! -nargs=0 RubyStdlib :call W3M_RubyStdlib()


" http://vimdoc.sourceforge.net/htmldoc/if_ruby.html
if !has('ruby')
  echo "Error: Required vim ruby"
  finish
endif

" 创建索引
ruby <<_EOF_
  require "json"
  $manual_search_w3m_buffer_num = {}
  def gen_php_index
    data = {
      "function" => [],
      "class" => [],
    }
    path = VIM::evaluate("g:php_manual_dir_path")
    Dir["#{path}/function*.html"].each do |f|
      name = File::basename f
      data["function"].push name
    end
    Dir["#{path}/class*.html"].each do |f|
      name = File::basename f
      data["class"].push name
    end
    begin
      File.write "#{Dir.home}/.vim_php_manual_index", JSON::dump(data)
    rescue
      return nil
    end
    data
  end
  def get_php_index
    begin
      data = JSON::load File.read "#{Dir.home}/.vim_php_manual_index"
    rescue
      data = nil
    end
    if !data then
      data = gen_php_index
    end
    data
  end
  def gen_php_sf_api_index
    require "find"
    require "nokogiri"
    begin
      path = VIM::evaluate "g:php_symfony2_api_manual_dir_path"
      File.open("#{Dir.home}/.vim_php_sf_api_index", "wb") do |fp|
        Find.find("#{path}/Symfony").each do |f|
          if File.extname(f) != ".html" then
            next
          end
          if File.exists? f[0..-6] then
            next
          end
          #p f
          file = f[path.length+1..-1]
          base_dir = File.dirname(file)
          Nokogiri::HTML.parse(File.read f).xpath('//div[@class="content"]/table/tr').each do |tr|
            td = tr.xpath('td')
            if td.length == 3
              td = td[1]
            else
              td = td[0]
            end
            f3 = td.xpath('a')
            if f3.length > 0 then
              f3 = File.join(base_dir, f3[0].attr('href'))
            else
              f3 = file
            end
            s = td.text.strip.gsub("\n", "")
            fp.write "#{f3} | #{s}\n"
          end
        end
      end
    end
  end
_EOF_

" 使用w3m打开文档文件
function! s:OpenUrl()
ruby <<_EOF_
  uri = VIM::evaluate("b:manual_path") + $curbuf[$curbuf.line_number].split(' | ')[0]
  manual_type = VIM::evaluate("b:manual_type")
  w3m_buffer_num = $manual_search_w3m_buffer_num[manual_type]
  if VIM::Window.count == 1 then
    VIM.command("vert botright vsplit")
  else
    VIM.command("wincmd w")
  end
  if w3m_buffer_num then
    buffer_num = w3m_buffer_num
    w3m_buffer_num = nil
    i = 0
    while i < VIM::Buffer.count
      if VIM::Buffer[i].number == buffer_num then
        w3m_buffer_num = buffer_num
        break
      end
      i = i + 1
    end
  end
  if w3m_buffer_num then
    VIM.command("b#{w3m_buffer_num}")
  end
  VIM.command("W3m #{uri}")
  $manual_search_w3m_buffer_num[manual_type] = $curbuf.number
_EOF_
endfunction

" 按键绑定
function! s:MapKeys()
    nnoremap <script> <silent> <buffer> <CR>          :call <SID>OpenUrl()<CR>
    nnoremap <script> <silent> <buffer> o             :call <SID>OpenUrl()<CR>
    nnoremap <script> <silent> <buffer> q             :bd<CR>
    for k in ["G", "n", "N", "L", "M", "H"]
        execute "nnoremap <buffer> <silent>" k ":keepjumps normal!" k."<CR>"
    endfor
endfunction

" PHP文档搜索
function! s:ManualPHPIndex()
ruby <<_EOF_
  gen_php_index
_EOF_
endfunction

function! s:ManualPHP(args)
  topleft new
  setlocal buftype=nofile
  let b:manual_path = g:php_manual_dir_path
  let b:manual_type = "php"

ruby <<_EOF_
  data = get_php_index
  if data
    i = 0
    key = VIM::evaluate "a:args"
    key.downcase!
    key.gsub!('-', '_')
    data.each do |k, v|
      v.each do |f|
        if f.gsub('-', '_').include? key then
          if i == 0 then
            $curbuf[1] = f
            i = i + 1
          else
            $curbuf.append $curbuf.line_number-1, f
          end
        end
      end
    end
  end
_EOF_

  call s:MapKeys()
  setlocal buftype=nofile readonly nomodifiable nowrap
  setlocal bufhidden=hide
endfunction

" Symfony api搜索
function! s:ManualSFIndex()
ruby <<_EOF_
  gen_php_sf_api_index
_EOF_
endfunction

function! s:ManualSF(args)
  topleft new
  setlocal buftype=nofile
  let b:manual_path = g:php_symfony2_api_manual_dir_path
  let b:manual_type = "sf_api"

ruby <<_EOF_
  i = 0
  key = VIM::evaluate "a:args"
  key.downcase!
  key.gsub!('-', '_')
  keys = key.split
  begin
    if keys.length > 0 then
      File.open("#{Dir.home}/.vim_php_sf_api_index").each { |line|
        value = line.gsub('-', '_')
        value.downcase!
        is_include = true
        keys.each do |k|
          if !value.include?(k) then
            is_include = false
            break
          end
        end
        if !is_include then
          next
        end
        if i == 0 then
          $curbuf[1] = line
          i = i + 1
        else
          $curbuf.append $curbuf.line_number-1, line
        end
      }
    end
  end
_EOF_

  call s:MapKeys()
  setlocal buftype=nofile readonly nomodifiable nowrap
  setlocal bufhidden=hide
endfunction

command! -nargs=1 -range ManualPHP :call s:ManualPHP(<f-args>)
command! -nargs=0 ManualPHPIndex :call s:ManualPHPIndex()
command! -nargs=1 -range ManualSF :call s:ManualSF(<f-args>)
command! -nargs=0 ManualSFIndex :call s:ManualSFIndex()

