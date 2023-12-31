% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TSLSTM.R
\name{LSTMModel}
\alias{LSTMModel}
\title{LSTMModel class}
\usage{
LSTMModel(
  lstm_model,
  scale_output,
  scaler_output,
  scale_input,
  scaler_input,
  tsLag,
  xregLag,
  model_structure
)
}
\arguments{
\item{lstm_model}{LSTM 'keras' model}

\item{scale_output}{indicate which type of scaler is used in the output}

\item{scaler_output}{Scaler of output variable (and lags)}

\item{scale_input}{indicate which type of scaler is used in the input(s)}

\item{scaler_input}{Scaler of input variable(s) (and lags)}

\item{tsLag}{Lag of time series data}

\item{xregLag}{Lag of exogenous variables}

\item{model_structure}{Summary of the LSTM model previous to training}
}
\value{
LSTMModel object
}
\description{
LSTMModel class for further use in predict function
}
\examples{
\donttest{
if (keras::is_keras_available()){
  y<-rnorm(100,mean=100,sd=50)
  x1<-rnorm(100,mean=50,sd=50)
  x2<-rnorm(100, mean=50, sd=25)
  x<-cbind(x1,x2)
  TSLSTM<-ts.lstm(ts=y,
                  xreg = x,
                  tsLag=2,
                  xregLag = 0,
                  LSTMUnits=5,
                  ScaleInput = 'scale',
                  ScaleOutput = 'scale',
                  Epochs=2)
}
}
}
\references{
Paul, R.K. and Garai, S. (2021). Performance comparison of wavelets-based machine learning technique for forecasting agricultural commodity prices, Soft Computing, 25(20), 12857-12873
}
