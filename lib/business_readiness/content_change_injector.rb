module BusinessReadiness
  class ContentChangeInjector
    def initialize(base_paths_with_tags)
      @base_paths_with_tags = base_paths_with_tags
    end

    def inject(base_path, existing_tags)
      new_tags = base_paths_with_tags[base_path]
      return existing_tags unless new_tags

      existing_tags.merge(new_tags) do |_, value1, value2|
        value1.concat(value2)
      end
    end

  private

    attr_reader :base_paths_with_tags
  end
end
