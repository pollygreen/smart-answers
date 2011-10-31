require 'ostruct'

module SmartAnswer
  class InvalidResponse < StandardError; end
  
  class Flow
    attr_reader :nodes
    attr_reader :outcomes
    attr_accessor :state
    
    def initialize(&block)
      @nodes = []
      @next_question_number = 1
      @state = nil
      instance_eval(&block) if block_given?
    end
    
    def display_name(text = nil)
      @display_name = text unless text.nil?
      @display_name
    end
    
    def multiple_choice(name, options = {}, &block)
      add_node Question::MultipleChoice.new(name, options, &block)
    end
    
    def outcome(name, options = {}, &block)
      add_node Outcome.new(name, options, &block)
    end
    
    def outcomes
      @nodes.select { |n| n.is_a?(Outcome) }
    end

    def questions
      @nodes.select { |n| n.is_a?(Question::Base) }
    end

    def node_exists?(node_or_name)
      ! node(node_or_name).nil?
    end
    
    def node(node_or_name)
      name = node_or_name.is_a?(Node) ? node_or_name.name : node_or_name.to_sym
      @nodes.find {|n| n.name == name }
    end
    
    def process(responses)
      start_state = OpenStruct.new(current_node: questions.first.name).freeze
      responses.inject(start_state) do |state, response|
        node(state.current_node).transition(state, response)
      end
    end
    
    def path(responses)
      start_state = OpenStruct.new(current_node: questions.first.name).freeze
      path, final_state = responses.inject([[], start_state]) do |memo, response|
        path, state = memo
        new_state = node(state.current_node).transition(state, response)
        [path + [state.current_node], new_state]
      end
      path
    end
    
    private
      def add_node(node)
        raise "Node #{node.name} already defined" if node_exists?(node)
        if node.is_a?(Question::Base)
          node.number = @next_question_number
          @next_question_number += 1
        end
        @nodes << node
      end
  end
end