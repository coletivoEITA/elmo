module Odk
  class QingDecorator < FormItemDecorator
    delegate_all

    def odk_code
      @odk_code = super
      @odk_code ||= "q#{object.question.id}"
    end

    def xpath_to(dest)
      dest = decorate(dest)
      return dest.absolute_xpath if dest.top_level?

      common_ancestor = object.lowest_common_ancestor(dest)
      ancestor_to_self = object.path_from_ancestor(common_ancestor, include_ancestor: true)
      ancestor_to_dest = decorate_collection(dest.path_from_ancestor(common_ancestor))

      if ancestor_to_dest.size > 0
        args = [dest.absolute_xpath]
        unless common_ancestor.root?
          root_to_ancestor = common_ancestor.path_from_ancestor(ancestors.first, include_self: true)
          root_to_ancestor = decorate_collection(root_to_ancestor)
          root_to_ancestor.each_with_index do |node, i|
            xpath_self_to_cur_group = ([".."] * (ancestry_depth - i - 1)).join("/")
            args << node.absolute_xpath << "position(#{xpath_self_to_cur_group})"
          end
        end

        ancestor_to_dest.each do |node|
          args << node.absolute_xpath << "1"
        end

        "indexed-repeat(#{args.join(',')})"
      else
        # use ../ to get to the common ancestor
        xpath_self_to_ancestor = ancestor_to_self.map{ ".." }.join("/")

        # use odk_codes to get to the other qing
        ancestor_to_dest += [dest]
        xpath_ancestor_to_dest = ancestor_to_dest.map(&:odk_code).join("/")

        [xpath_self_to_ancestor, xpath_ancestor_to_dest].join("/")
      end
    end

    def has_default?
      default.present? && qtype.defaultable?
    end

    def subqings
      decorate_collection(object.subqings)
    end

    def jr_preload
      case metadata_type
      when "formstart", "formend" then "timestamp"
      else nil
      end
    end

    def jr_preload_params
      case metadata_type
      when "formstart" then "start"
      when "formend" then "end"
      else nil
      end
    end
  end
end
