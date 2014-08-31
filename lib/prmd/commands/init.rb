module Prmd
  def self.example_for_type(t)
    case t
    when 'number'
      7
    when 'string'
      'abcdefg'
    when 'boolean'
      true
    when 'object'
      {}
    when 'array'
      []
    end
  end

  def self.init(resource, options={})
    data = {
      '$schema'     => 'http://json-schema.org/draft-04/hyper-schema',
      'title'       => 'FIXME',
      'description' => 'FIXME',
      'type'        => ['object'],
      'definitions' => {},
      'links'       => [],
      'properties'  => {},
    }

    schema = Prmd::Schema.new(data)

    fields = options[:fields] || []
    #name:string,age:integer
    fields = fields.map { |x| x.split(':') }

    if resource
      if resource.include?('/')
        parent, resource = resource.split('/')
      end
      schema['id']    = "schemata/#{resource}"
      schema['title'] = "FIXME - #{resource[0...1].upcase}#{resource[1..-1]}"
      schema['definitions'] = {
        "id" => {
          "description" => "unique identifier of #{resource}",
          "example"     => "01234567-89ab-cdef-0123-456789abcdef",
          "format"      => "uuid",
          "type"        => ["string"]
        },
        "identity" => {
          "$ref" => "/schemata/#{resource}#/definitions/id"
        },
        "created_at" => {
          "description" => "when #{resource} was created",
          "example"     => "2012-01-01T12:00:00Z",
          "format"      => "date-time",
          "type"        => ["string"]
        },
        "updated_at" => {
          "description" => "when #{resource} was updated",
          "example"     => "2012-01-01T12:00:00Z",
          "format"      => "date-time",
          "type"        => ["string"]
        }
      }
      if ! options[:uuid]
        schema['definitions']['id'] = {
          "description" => "unique identifier of #{resource}",
          "example"     => "53eb3bb3772d583e3c030000",
          "pattern"     => "^[a-z0-9]{24}$",
          "type"        => ["string"]
        }
      end
      fields.each { |f,t|
        schema['definitions'][f] = {
          "description" => "#{resource} #{f}",
          "example"     => self.example_for_type(t),
          "type"        => [t]
        }
        if f=='name'
          schema['definitions']['identity'] = {
            'anyOf' => [
              {"$ref" => "/schemata/#{resource}#/definitions/id"},
              {"$ref" => "/schemata/#{resource}#/definitions/name"}
            ]
          }
        end
      }
      schema['links'] = [
        {
          "description"   => "Create a new #{resource}.",
          "href"          => "/#{resource}s",
          "method"        => "POST",
          "rel"           => "create",
          "title"         => "Create"
        },
        {
          "description"   => "Delete an existing #{resource}.",
          "href"          => "/#{resource}s/{(/schemata/#{resource}#/definitions/identity)}",
          "method"        => "DELETE",
          "rel"           => "destroy",
          "title"         => "Delete"
        },
        {
          "description"   => "Info for existing #{resource}.",
          "href"          => "/#{resource}s/{(/schemata/#{resource}#/definitions/identity)}",
          "method"        => "GET",
          "rel"           => "self",
          "title"         => "Info"
        },
        {
          "description"   => "List existing #{resource}s.",
          "href"          => "/#{resource}s",
          "method"        => "GET",
          "rel"           => "instances",
          "title"         => "List"
        },
        {
          "description"   => "Update an existing #{resource}.",
          "href"          => "/#{resource}s/{(/schemata/#{resource}#/definitions/identity)}",
          "method"        => "PATCH",
          "rel"           => "update",
          "title"         => "Update"
        }
      ]
      if parent
        schema['links'] << {
          "description"  => "List existing #{resource}s for existing #{parent}.",
          "href"         => "/#{parent}s/{(/schemata/#{parent}#/definitions/identity)}/#{resource}s",
          "method"       => "GET",
          "rel"          => "instances",
          "title"        => "List"
        }
      end
      schema['properties'] = {
        "id"          => { "$ref" => "/schemata/#{resource}#/definitions/id" },
        "created_at"  => { "$ref" => "/schemata/#{resource}#/definitions/created_at" },
        "updated_at"  => { "$ref" => "/schemata/#{resource}#/definitions/updated_at" }
      }
      fields.each { |f,t|
        schema['properties'][f] = {
          "$ref" => "/schemata/#{resource}#/definitions/#{f}" 
        }
      }
    end

    if options[:yaml]
      schema.to_yaml
    else
      schema.to_json
    end
  end
end
