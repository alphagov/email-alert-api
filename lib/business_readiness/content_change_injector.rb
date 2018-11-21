module BusinessReadiness
  class ContentChangeInjector
    def initialize(base_paths_with_tags)
      @base_paths_with_tags = base_paths_with_tags
    end

    def inject(base_path, existing_tags)
      new_tags = base_paths_with_tags[base_path]
      return existing_tags unless new_tags

      return new_tags unless existing_tags

      existing_tags.merge(new_tags) do |_, value1, value2|
        if value2.is_a?(Array)
          Array(value1).concat(value2)
        else
          value2
        end
      end
    end

  private

    attr_reader :base_paths_with_tags
  end
end
