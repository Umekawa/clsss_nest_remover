# frozen_string_literal: true

# @param parent_names [Array<Array<String>>]
# @return [String]
def class_names(parent_names)
  names = []
  parent_names.each do |elements|
    if names.length.eql?(0)
      names = elements
    else
      f = []
      names.each do |name|
        elements.each do |element|
          f.append(name + element)
        end
      end
      names = f
    end
  end
  names.join(",\n")
end

# @param s [String]
# @return [String]
def remove_extend_class(s)
  open_num = 0
  parent_names = []
  styles = []
  style = []
  line = ''
  i = 0
  while i < s.length
    case s[i]
    when '/'
      if s[i + 1].eql?('/')
        until s[i].eql?("\n") || s[i].eql?(nil)
          # line += s[i] コメントがおかしい場所に出るので出さないようにしてます
          i += 1
        end
      elsif s[i + 1].eql?('*')
        until s[i].eql?('*') && s[i + 1].eql?('/')
          # line += s[i] コメントがおかしい場所に出るので出さないようにしてます
          i += 1
        end
      else
        line += s[i]
        i += 1
      end
    when '{'
      line += '{'
      i += 1
      open_num += 1
    when '&'
      if s[i + 1].eql?(':')
        line += s[i]
        i += 1
      else
        parent_name = ''
        names = []
        until s[i].eql?(' ') || s[i].eql?('{') || s[i].eql?('/') || s[i].eql?(nil)
          if (s[i].eql?(','))
            names.append(parent_name.strip.delete('&'))
            parent_name = ''
            i += 1
          else
            parent_name += s[i]
            i += 1
          end
        end
        names.append(parent_name.strip.delete('&'))
        parent_names.append(names)
        style.append('')
        open_num -= 1
      end
    when '}'
      line += '}'
      i += 1
      open_num -= 1
      if open_num.eql?(0)
        class_name = class_names(parent_names)
        parent_names.pop
        styles.append(class_name + style.pop + line)
        line = ''
        open_num += 1 unless parent_names.empty?
      end
    when ' '
      line += ' '
      i += 1
    when "\n"
      if !parent_names.empty? && line.strip != ''
        style[-1] += line + "\n"
      elsif !parent_names.empty?
        style[0] += line + "\n"
      end
      line = ''
      i += 1
    when "@"
      if s[i..i + 6].eql?('@import') || s[i..i + 7].eql?('@include')
        while (!s[i].eql?("\n") && !s[i].nil?)
          line += s[i]
          i += 1
        end
        unless s[i].eql?(nil)
          line += s[i]
          i += 1
        end
      else
        while (!s[i].eql?('}'))
          line += s[i]
          i += 1
        end
      end
    else
      if parent_names.length.eql?(0) && !(s[i].eql?(' ') || s[i].eql?('{') || s[i].eql?(nil))
        parent_name = ''
        names = []
        until s[i].eql?(' ') || s[i].eql?('{') || s[i].eql?('/') || s[i].eql?(nil)
          if (s[i].eql?(','))
            names.append(parent_name.strip)
            parent_name = ''
            i += 1
          else
            parent_name += s[i]
            i += 1
            style.append('')
          end
        end
        names.append(parent_name.strip)
        parent_names.append(names)
      else
        line += s[i]
        i += 1
      end
    end
  end
  unless line.eql?('')
    styles.append("#{style.join("")}#{line}")
  end
  puts line
  puts styles

  s = styles.join("\n\n")
  i = 0
  spaces = 0
  next_spaces = 0
  lines = s.split("\n")
  s = lines.map.with_index do |line, i|
    next_spaces += line.count('{')
    spaces -= line.count('}')
    next_spaces -= line.count('}')
    line = line.length > 0 && spaces > 0 ? ' ' * spaces * 2 + line : line
    spaces = next_spaces
    if line.count('}') > 0 && !lines[i + 1].nil? && lines[i + 1].count('}').eql?(0) && !lines[i + 1].length.eql?(0)
      line += "\n"
    end
    line
  end.join("\n") + "\n"
end

def remove_nest(file_path)
  s = ''
  File.open(file_path, 'r') do |f|
    f.each_line do |line|
      line = line.strip.gsub('{', "{\n").gsub('}', "}\n")
      s += line[-1].eql?("\n") ? line : "#{line}\n"
    end
  end
  s
end

def main
  target_dir = ARGV[0]
  if target_dir.eql?(nil)
    puts 'Please input attempt folder'
    exit
  end
  puts "target_dir: #{target_dir}"

  Dir.glob('**/_*.scss', File::FNM_DOTMATCH, base: target_dir).each do |file|
    file_path = File.join(target_dir, file)
    next unless file_path

    puts file_path
    s = remove_nest(file_path)
    styles = remove_extend_class(s)
    #puts styles
    File.open(file_path, 'w') do |f|
      f.write(styles)
    end
  end
end

if File.basename(__FILE__) == File.basename($0)
  main
end
