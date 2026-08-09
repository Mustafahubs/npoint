import React, { Component } from 'react'
import PropTypes from 'prop-types'

import {} from './Footer.css'

export default class Footer extends Component {
  static propTypes = {
    light: PropTypes.bool,
  }

  render() {
    let sectionClassName = `section ${
      this.props.light ? ' dark-white less-padding' : ' blue'
    }`

    return (
      <footer className="footer">
        <div className={sectionClassName}>
          <div className="container hidden-sm-up text-center">
            <div className="footer-line-xs">n:point &copy; 2018&ndash;2026</div>
            <div className="footer-line-xs">
              Maintained by{' '}
              <a target="_blank" href="https://github.com/Mustafahubs">
                Mustafahubs
              </a>{' '}
              · Code on{' '}
              <a target="_blank" href="https://github.com/Mustafahubs/npoint">
                GitHub
              </a>
            </div>
            <div className="footer-line-xs">
              Originally created by{' '}
              <a target="_blank" href="https://github.com/azirbel/npoint">
                Alex Zirbel
              </a>
            </div>
            <br />
            <div className="footer-line-xs">
              Questions?{' '}
              <a href="mailto:sgocean25@gmail.com">sgocean25@gmail.com</a>
            </div>
          </div>
          <div className="container hidden-xs-down">
            <div className="row">
              <div className="col-xs-6">
                <div className="footer-line-1">n:point &copy; 2018&ndash;2026</div>
                <div>
                  Maintained by{' '}
                  <a target="_blank" href="https://github.com/Mustafahubs">
                    Mustafahubs
                  </a>{' '}
                  · Code on{' '}
                  <a target="_blank" href="https://github.com/Mustafahubs/npoint">
                    GitHub
                  </a>
                </div>
                <div className="footer-line-xs">
                  Originally created by{' '}
                  <a target="_blank" href="https://github.com/azirbel/npoint">
                    Alex Zirbel
                  </a>
                </div>
              </div>
              <div className="col-xs-6 text-right">
                <div>
                  Questions?{' '}
                  <a href="mailto:sgocean25@gmail.com">sgocean25@gmail.com</a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </footer>
    )
  }
}
