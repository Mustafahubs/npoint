class SchemaController < ApplicationController
  # Rails' ParamsWrapper nests a copy of the body under a `schema` key
  # (inferred from this controller's name) even when the client doesn't send
  # one, which would otherwise mask a genuinely-missing `schema` param.
  wrap_parameters false

  def validate
    contents = parse_required_json(:contents)
    schema = parse_required_json(:schema)
    return if performed? # a parse failure already rendered a response

    errors = JSON::Validator.fully_validate(schema, contents)
    render json: {
      valid: errors.blank?,
      errors: errors.map { |e| improve_readability(e) }
    }
  end

  def generate
    contents = parse_required_json(:contents)
    return if performed?

    schema = JSON.parse(
      JSON::SchemaGenerator.generate(
        'npoint',
        contents.to_json,
        {:schema_version => 'draft4'}
      )
    )

    # Mostly just confusing information
    schema.delete('$schema')
    schema.delete('description')

    render json: {
      schema: schema,
      original_schema: JSON.pretty_generate(schema),
    }
  end

  private

  # Renders a 400 and returns nil if `param` isn't present or isn't valid
  # JSON; callers must check `performed?` before using the result.
  def parse_required_json(param)
    JSON.parse(params.require(param))
  rescue JSON::ParserError, TypeError
    head :bad_request
    nil
  end

  def improve_readability(error_message)
    msg = error_message
    msg = strip_schema_id(msg)
    msg = rename_root_element(msg)
    msg = rename_root_reference(msg)
    msg
  end

  def strip_schema_id(error_message)
    error_message.gsub(/ in schema [a-z0-9-]*$/, '')
  end

  # BAD:
  # The property '#/' of type array did not match the following type: object
  # The property '#/' did not contain a required property of 'a'
  #
  # GOOD:
  # The data did not match the following type: object
  # The data did not contain a required property of 'a'
  def rename_root_element(error_message)
    error_message.gsub(/^The property \'#\/\'( of type array)?/, 'The data')
  end

  # BAD:
  # The property '#/b' did not contain a required property of 'a'
  #
  # GOOD:
  # The property 'b' did not contain a required property of 'a'
  def rename_root_reference(error_message)
    error_message.gsub(/^The property \'#\//, "The property '")
  end
end
