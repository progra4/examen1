require './models'
require 'json'
module Controllers
  class NotFoundException < Exception; end

  class Controller
    
    attr_accessor :request

    def initialize(request)
      @request = request
    end

    def route
      collection_pattern = /\/#{resource_name}$/
      member_pattern     = /\/#{resource_name}\/([a-z0-9\-]+)/


      #collection actions
      if request.path =~ collection_pattern
        if request.get?
          return index
        elsif request.post?
          return create
        else
          return [405, ""]
        end
      end
      
      #member actions
      if request.path =~ member_pattern
        request.params["id"] = request.path.match(member_pattern)[1]
        if request.get?
          # show <=> read
          return show
        elsif request.put?
          return update
        elsif request.delete?
          return destroy
        else
          return [405, ""]
        end
      end

      #a not implemented path was requested
      return [501, ""]
    end


    def dispatch
      begin
        status, body = route
        accept = request.env['HTTP_ACCEPT'] || "text/plain"
        headers = {'Content-Type' => accept}
        if status < 400
          if  accept == "text/plain" || accept == "*/*"
            [status, headers, body.is_a?(Array) ? body.map(&:as_text).join("\n") : body.as_text]
          elsif accept == "text/html"
            [status, headers, body]
          elsif accept == "application/json"
            [status, headers, JSON.dump(body)]
          end
        else
          [status, {'Content-Type' => 'text/plain'}, body]
        end
      rescue NotFoundException
        [404, {'Content-Type' => 'text/plain'}, "Not found"]
      rescue 
        [500, {'Content-Type' => 'text/plain'}, "Server Error"]
      end
    end
  end


  class  TasksController < Controller
    include Models

    def resource_name
      "tasks"
    end

    def index
      unless request.params["assignee"]
        [200, Task.all]
      else
        [200, Task.where(assignee: request.params["assignee"].downcase)]
      end
    end

    def show
      task = Task.find(request.params["id"])
      if task
        [200, task]
      else
        raise NotFoundException
      end
    end

    def create

      if Task.exists?(description: request.params["description"].downcase)
        return [422, "Task already exists"]
      elsif request.params["description"].empty?
        return [400, "Description can't be blank"]
      end

      task = Task.create(
        description: request.params["description"],
        assignee:  (request.params["assignee"].downcase rescue ""),
        priority: request.params["priority"] || 1
      )

      [201, task]
    end

    def update
      task = Task.find(request.params["id"])

      if Task.exists?(description: request.params["description"].downcase)
        return [422, "Task already exists"]
      elsif request.params["description"].empty?
        return [400, "Description can't be blank"]
      end

      task.update(
        description: request.params["description"],
        assignee: (request.params["assignee"].nil? ? task.assignee : request.params["assignee"]),
        priority: (request.params["priority"].nil? ? task.priority : request.params["priority"])
      )

      [200, task]
    end

    def destroy
      task = Task.find(request.params["id"])
      if task
        task.delete
        [200, task]
      else
        raise NotFoundException
      end
    end
  end
end
