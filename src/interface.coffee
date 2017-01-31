class survey extends AnnotationIteration

  _this = undefined
  questionsQuery = '.interfaces-staging >:not(.template) .questions-container .question'
  qestionTemplatesQuery = '.interfaces-staging >:not(.template) .question-templates'

  # uncomment to overwrite interface registration at AnnotationLifecylce
  constructor: ->
    _this = this
    this.$questions = $(questionsQuery)
    this.questions = []

    this.initQuestions()

    super

  initQuestions: ->
    this.$questions.each (_, element) ->
      $question = $(element)
      question = {
        $question: $question,
        mandatory: $question.data('mandatory'),
        scale: $question.data('scale'),
        value_type: $question.data('value-type'),
        value_unit: $question.data('value-unit'),
        values: $question.data('values'),
        bounds: {
          lower: {
            value: $question.data('bounds-lower-value'),
            label: $question.data('bounds-lower-label')
          },
          upper: {
            value: $question.data('bounds-upper-value'),
            label: $question.data('bounds-upper-label')
          }
        },
        question_id: $question.data('question-id'),
        selected: -1
      }
      _this.questions.push(question)

      if question.scale == 'interval'
        $('input', element).attr('name', question.question_id)

      else if question.scale == 'ratio'
        _this.renderFader(question, element)

  renderFader: (question, context) ->
    template = $("#{qestionTemplatesQuery} .ratio-scale-question")[0].outerHTML
    template = template.replace(new RegExp('{#{', 'g'), '{{')
    template = template.replace(new RegExp('}#}', 'g'), '}}')

    renderedTemplate = Mustache.render(template, question)
    $('.question-values', context).html(renderedTemplate)

    $faderInput = $('.ratio-scale-question input', context)
    initValue = ($faderInput.attr('max') - $faderInput.attr('min')) / 2
    $faderInput.attr('value', initValue)

  render: (template, data) ->
    window.surveyPayload = data
    super

  saveAnnotation: ->
    console.log('save payload!')
    this.saveChanges('wow')

window.survey = new survey()
