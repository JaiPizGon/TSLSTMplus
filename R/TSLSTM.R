#' @title Prepare data for Long Short Term Memory (LSTM) Model for Time Series Forecasting
#' @description The LSTM (Long Short-Term Memory) model is a Recurrent Neural Network (RNN) based architecture that is widely used for time series forecasting. Min-Max transformation has been used for data preparation. Here, we have used one LSTM layer as a simple LSTM model and a Dense layer is used as the output layer. Then, compile the model using the loss function, optimizer and metrics. This package is based on 'keras' and TensorFlow modules.
#' @param ts Time series data
#' @param xreg Exogenous variables
#' @param tsLag Lag of time series data
#' @param xregLag Lag of exogenous variables
#' @export
#' @return dataset with all lags created from exogenous and time series data.
#' @examples
#'   y <- rnorm(100,mean=100,sd=50)
#'   x1 <- rnorm(100,mean=50,sd=50)
#'   x2 <- rnorm(100, mean=50, sd=25)
#'   x <- cbind(x1,x2)
#'   ts.prepare.data(y, x, 2, 4)
ts.prepare.data <- function(ts,
                            xreg = NULL,
                            tsLag,
                            xregLag = 0) {
  feature_mat <- NULL
  var_names <- NULL

  # Handling time series and external regressors
  if (!is.null(xreg)) {
    exo_v <- ifelse(is.null(dim(xreg)[2]), 1, dim(xreg)[2])
    if (length(xregLag) != 1 && length(xregLag) != exo_v) {
      stop('Dimension of xregLag does not coincide with number of exogenous variables.')
    }
    if (length(xregLag) == 1) {
      xregLag <- rep(xregLag, exo_v)
    }
    for (var in 1:exo_v) {
      xregLag_v <- xregLag[var]
      lag_x <- lagmatrix(as.ts(xreg[, var]), lag = c(0:xregLag_v))
      var_names <- c(var_names, paste(colnames(xreg)[var], c(0:xregLag_v), sep='_'))
      feature_mat <- cbind(feature_mat, lag_x)
    }

  }

  tsLag <- ifelse(is.null(tsLag), 0, tsLag)
  lag_y <- lagmatrix(as.ts(ts), lag = c(0:(tsLag)))
  var_names <- c(paste('y', c(0:tsLag), sep='_'), var_names)
  all_feature <- data.frame(cbind(lag_y, feature_mat))
  colnames(all_feature) <- var_names

  data_all <- all_feature
  # Adjusting data based on lag
  if (is.null(xregLag)) xregLag <- 0

  if (sum(c(xregLag, tsLag)) > 0) {
    if (max(xregLag) >= tsLag) {
      data_all <- all_feature[-c(1:max(xregLag)),]
    } else {
      data_all <- all_feature[-c(1:tsLag),]
    }
  }

  return(data_all)
}

#' @title Long Short Term Memory (LSTM) Model for Time Series Forecasting
#' @description The LSTM (Long Short-Term Memory) model is a Recurrent Neural Network (RNN) based architecture that is widely used for time series forecasting. Min-Max transformation has been used for data preparation. Here, we have used one LSTM layer as a simple LSTM model and a Dense layer is used as the output layer. Then, compile the model using the loss function, optimizer and metrics. This package is based on 'keras' and TensorFlow modules.
#' @param ts Time series data
#' @param xreg Exogenous variables
#' @param tsLag Lag of time series data. If NULL, no lags of the output are used.
#' @param xregLag Lag of exogenous variables
#' @param LSTMUnits Number of unit in LSTM layers
#' @param DenseUnits Number of unit in Extra Dense layers. A Dense layer with a single neuron is always added at the end.
#' @param DropoutRate Dropout rate
#' @param Epochs Number of epochs
#' @param CompLoss Loss function
#' @param CompMetrics Metrics
#' @param Optimizer 'keras' optimizer
#' @param ScaleOutput Flag to indicate if ts shall be scaled before training
#' @param ScaleInput Flag to indicate if xreg shall be scaled before training
#' @param BatchSize Batch size to use during training
#' @param LSTMActivationFn Activation function for LSTM layers
#' @param LSTMRecurrentActivationFn Recurrent activation function for LSTM layers
#' @param DenseActivationFn Activation function for Extra Dense layers
#' @param ValidationSplit Validation split ration
#' @param verbose Indicate how much information is given during training. Accepted values, 0, 1 or 2.
#' @param RandomState seed for replication
#' @param EarlyStopping EarlyStopping according to 'keras'
#' @param LagsAsSequences Use lags as previous timesteps of features, otherwise use them as "extra" features.
#' @param Stateful Flag to indicate if LSTM layers shall retain its state between batches.
#' @param ... Extra arguments passed to keras::layer_lstm
#' @import keras tensorflow tsutils stats
#' @return LSTMmodel object
#' @export
#' @examples
#' \donttest{
#'   if (keras::is_keras_available()){
#'       y<-rnorm(100,mean=100,sd=50)
#'       x1<-rnorm(100,mean=50,sd=50)
#'       x2<-rnorm(100, mean=50, sd=25)
#'       x<-cbind(x1,x2)
#'       TSLSTM<-ts.lstm(ts=y,
#'                       xreg = x,
#'                       tsLag=2,
#'                       xregLag = 0,
#'                       LSTMUnits=5,
#'                       ScaleInput = 'scale',
#'                       ScaleOutput = 'scale',
#'                       Epochs=2)
#'   }
#' }
#' @references
#' Paul, R.K. and Garai, S. (2021). Performance comparison of wavelets-based machine learning technique for forecasting agricultural commodity prices, Soft Computing, 25(20), 12857-12873
ts.lstm <- function(ts,
                    xreg = NULL,
                    tsLag = NULL,
                    xregLag = 0,
                    LSTMUnits,
                    DenseUnits = NULL,
                    DropoutRate = 0.00,
                    Epochs = 10,
                    CompLoss = "mse",
                    CompMetrics = "mae",
                    Optimizer = optimizer_rmsprop,
                    ScaleOutput = c(NULL, "scale", "minmax"),
                    ScaleInput = c(NULL, "scale", "minmax"),
                    BatchSize = 1,
                    LSTMActivationFn = 'tanh',
                    LSTMRecurrentActivationFn = 'sigmoid',
                    DenseActivationFn = 'relu',
                    ValidationSplit = 0.1,
                    verbose=2,
                    RandomState=NULL,
                    EarlyStopping=callback_early_stopping(monitor = "val_loss",
                                                min_delta = 0,
                                                patience = 3,
                                                verbose = 0,
                                                mode = "auto"),
                    LagsAsSequences = TRUE,
                    Stateful = FALSE,
                    ...
                    ) {
  if (!is.null(RandomState)) {
    set_random_seed(RandomState)
  }
  ## Check the option for scalers
  ScaleOutput <- match.arg(ScaleOutput)
  ScaleInputs <- match.arg(ScaleInput)

  ## Scale input and output data
  scaler_input <- NULL
  scaler_output <- NULL

  if (!is.null(ScaleInput) && !is.null(xreg)) {

    if (ScaleInput == 'scale') {
      scaler_input <- scale(xreg)
      xreg <- scaler_input[,,drop=FALSE]
      scaler_input <- list(center = attr(scaler_input, "scaled:center"),
                           scale = attr(scaler_input, "scaled:scale"))
    }

    if (ScaleInput == 'minmax') {
      scaler_input <- minmax_scale(xreg)
      xreg <- scaler_input[,,drop=FALSE]
      scaler_input <- list(min = attr(scaler_input, "scaled:min"),
                           range = attr(scaler_input, "scaled:range"))

    }
  }

  if (!is.null(ScaleOutput)) {
    if (ScaleOutput == 'scale') {
      scaler_output <- scale(ts)
      ts <- scaler_output[,]
      scaler_output <- list(center = attr(scaler_output, "scaled:center"),
                            scale = attr(scaler_output, "scaled:scale"))
    }

    if (ScaleOutput == 'minmax') {
      scaler_output <- minmax_scale(ts)
      ts <- scaler_output[,]
      scaler_output <- list(min = attr(scaler_output, "scaled:min"),
                            range = attr(scaler_output, "scaled:range"))
    }
  }

  if (is.null(xreg) && (is.null(tsLag) || tsLag == 0)) {
    stop('LSTM training needs output lags and/or external regressors.')
  }

  if (Stateful && !LagsAsSequences) {
    warning("Lags shall be treated as sequences if LSTM is stateful. Turning LagsAsSequences to TRUE")
    LagsAsSequences <- TRUE
  }

  if (is.null(xreg)) {
    # Set xreglag as null when no external regressors are passed
    xregLag <- NULL
  }

  # Check if all lags are declared as necessary for stateful training
  if (LagsAsSequences) {
    max_lag <- max(c(xregLag, tsLag))
    if (is.null(tsLag)) {
      if (!all(xregLag == max_lag)) {
        warning(paste0('Training a LSTM with LagsAsSequences needs the same lags for all inputs.\nLSTM will be train with', max_lag, 'for inputs.', sep=' '))

        xregLag <- max_lag
      }
    } else {
      if (!all(c(xregLag, tsLag) == max_lag)) {
        warning(paste0('Training a LSTM with LagsAsSequences needs the same lags for all inputs and output.LSTM will be train with', max_lag, 'for inputs and output.', sep=' '))
        tsLag <- xregLag <- max_lag
      }
    }
  }

  ### Lag selection and data matrix preparation ###
  data <- ts.prepare.data(ts, xreg, tsLag, xregLag)


  # Split between inputs and output
  inputs <- data[, -1, drop=FALSE]
  output <- data[, 1]

  # Data Array Preparation for LSTM
  if (LagsAsSequences) {
    if (!is.null(xreg)) {
      feature <- ifelse(is.null(dim(xreg)), ncol(xreg), dim(xreg)[2]) + ifelse(is.null(tsLag) || tsLag == 0, 0, 1)
    } else {
      feature <- 1
    }
    x_lstm <- array(data.matrix(inputs), c(dim(inputs)[1], max(c(tsLag, xregLag)), feature))
    x_lstm <- x_lstm[,dim(x_lstm)[2]:1,, drop=FALSE] # Reverse order of lags
  } else {
    # Preparing data for the model
    feature <- ncol(data) - 1
    x_lstm <- data.matrix(inputs)
    dim(x_lstm) <- c(dim(x_lstm)[1], 1, feature)
  }
  y_lstm <- data.matrix(output)

  # LSTM model construction
  lstm_model <- keras_model_sequential()
  input_layer <- TRUEtotal_layers <- length(LSTMUnits)

  total_layers <- length(LSTMUnits)

  for (i in seq_along(LSTMUnits)) {
    lstmn <- LSTMUnits[i]

    # Check if the current layer is the last one
    is_last_layer <- (i == total_layers)

    if (input_layer) {
      lstm_model <- lstm_model %>% layer_lstm(
        units = lstmn,
        batch_input_shape  = c(BatchSize, ifelse(LagsAsSequences, max_lag, 1), feature),
        activation = LSTMActivationFn,
        recurrent_activation = LSTMRecurrentActivationFn,
        dropout = DropoutRate,
        return_sequences = !is_last_layer,
        stateful = Stateful,
        ...
      )
      input_layer <- FALSE
    } else {
      lstm_model <- lstm_model %>% layer_lstm(
        units = lstmn,
        activation = LSTMActivationFn,
        dropout = DropoutRate,
        return_sequences = !is_last_layer,
        stateful = Stateful,
        ...
      )

    }

  }

  # Add Extra Dense Layers
  for (du in DenseUnits) {
    lstm_model <- lstm_model %>% layer_dense(units = du,
                                             activation = DenseActivationFn)
  }

  # Add Final Dense Layer for output
  lstm_model <- lstm_model %>% layer_dense(units = 1, activation = 'linear')

  # Compiling the LSTM model
  lstm_model %>% compile(optimizer = Optimizer(),
                         loss = CompLoss,
                         metrics = CompMetrics)

  # Model summary
  if (verbose > 0) summary(lstm_model)

  model_structure <- capture.output(summary(lstm_model))


  if (!is.null(EarlyStopping)) {
    EarlyStopping <- list(EarlyStopping)
  }
  # Fitting the model on training data
  if (LagsAsSequences) {

    if (ValidationSplit > 0) {
      total_samples <- dim(x_lstm)[1]
      train_size <- floor(total_samples * (1-ValidationSplit))
      x_valid <- x_lstm[(train_size + 1):total_samples,,, drop=FALSE]
      y_valid <- y_lstm[(train_size + 1):total_samples,, drop=FALSE]
      x_lstm <- x_lstm[1:train_size,,, drop=FALSE]
      y_lstm <- y_lstm[1:train_size,, drop=FALSE]
      data_valid <- list(x_valid, y_valid)
      steps_valid <- floor(dim(y_valid)[1] / BatchSize)
    } else {
      data_valid <- NULL
      steps_valid <- NULL
    }

    if (Stateful){
      for (e in 1:Epochs) {
        print(paste0("Epoch ", e, "/", Epochs))
        lstm_history <- lstm_model %>%
          fit(
            x_lstm, y_lstm,
            batch_size = BatchSize,
            verbose = verbose,
            steps_per_epoch = floor(dim(y_lstm)[1] / BatchSize),
            validation_data = data_valid,
            validation_steps = steps_valid,
            callbacks = EarlyStopping,
            epochs = 1
          )

        lstm_model %>% reset_states()
      }
    } else {
      lstm_history <- lstm_model %>%
        fit(
          x_lstm, y_lstm,
          batch_size = BatchSize,
          verbose = verbose,
          # steps_per_epoch = floor(dim(y_lstm)[1] / BatchSize),
          validation_data = data_valid,
          # validation_steps = steps_valid,
          callbacks = EarlyStopping,
          epochs = Epochs
        )

    }
  } else {
    lstm_history <- lstm_model %>%
      fit(
        x_lstm, y_lstm,
        batch_size = BatchSize,
        epochs = Epochs,
        validation_split = ValidationSplit,
        verbose = verbose,
        callbacks = EarlyStopping,
        shuffle = FALSE
      )
  }

  # Create an LSTMModel object with additional parameters
  lstm_model_object <- LSTMModel(lstm_model,
                                 ScaleOutput, scaler_output,
                                 ScaleInput, scaler_input,
                                 tsLag, xregLag,
                                 model_structure,
                                 BatchSize,
                                 LagsAsSequences,
                                 Stateful)

  return(lstm_model_object)
}

#' @title LSTMModel class
#' @description LSTMModel class for further use in predict function
#' @param lstm_model LSTM 'keras' model
#' @param scale_output indicate which type of scaler is used in the output
#' @param scaler_output Scaler of output variable (and lags)
#' @param scale_input indicate which type of scaler is used in the input(s)
#' @param scaler_input Scaler of input variable(s) (and lags)
#' @param tsLag Lag of time series data
#' @param xregLag Lag of exogenous variables
#' @param model_structure Summary of the LSTM model previous to training
#' @param batch_size Batch size used during training of the model
#' @param lags_as_sequences Flag to indicate the model has been trained statefully
#' @param stateful Flag to indicate if LSTM layers shall retain its state between batches.
#' @return LSTMModel object
#' @export
#' @examples
#' \donttest{
#' if (keras::is_keras_available()){
#'   y<-rnorm(100,mean=100,sd=50)
#'   x1<-rnorm(100,mean=50,sd=50)
#'   x2<-rnorm(100, mean=50, sd=25)
#'   x<-cbind(x1,x2)
#'   TSLSTM<-ts.lstm(ts=y,
#'                   xreg = x,
#'                   tsLag=2,
#'                   xregLag = 0,
#'                   LSTMUnits=5,
#'                   ScaleInput = 'scale',
#'                   ScaleOutput = 'scale',
#'                   Epochs=2)
#' }
#' }
#' @references
#' Paul, R.K. and Garai, S. (2021). Performance comparison of wavelets-based machine learning technique for forecasting agricultural commodity prices, Soft Computing, 25(20), 12857-12873

LSTMModel <- function(lstm_model,
           scale_output,
           scaler_output,
           scale_input,
           scaler_input,
           tsLag,
           xregLag,
           model_structure,
           batch_size,
           lags_as_sequences,
           stateful) {
    structure(
      list(
        lstm_model = lstm_model,
        scale_output = scale_output,
        scaler_output = scaler_output,
        scale_input = scale_input,
        scaler_input = scaler_input,
        tsLag = tsLag,
        xregLag = xregLag,
        model_structure = model_structure,
        batch_size = batch_size,
        lags_as_sequences = lags_as_sequences,
        stateful = stateful
      ),
      class = "LSTMModel"
    )
  }

#' Predict using a Trained LSTM Model
#'
#' @description This function makes predictions using a trained LSTM model for time series forecasting. It performs iterative predictions where each step uses the prediction from the previous step. The function takes into account the lags in both the time series data and the exogenous variables.
#'
#' @param object An LSTMModel object containing a trained LSTM model along with normalization parameters and lag values.
#' @param horizon The number of future time steps to predict.
#' @param ts A vector or time series object containing the historical time series data. It should have a number of observations at least equal to the lag of the time series data.
#' @param xreg (Optional) A matrix or data frame of exogenous variables to be used for prediction. It should have a number of rows at least equal to the lag of the exogenous variables.
#' @param xreg.new (Optional) A matrix or data frame of exogenous variables to be used for prediction. It should have a number of rows at least equal to the lag of the exogenous variables.
#' @param BatchSize (Optional) Batch size to use during prediction
#' @param ... Optional arguments, no use is contemplated right now
#' @return A vector containing the forecasted values for the specified horizon.
#' @examples
#' \donttest{
#'   if (keras::is_keras_available()){
#'       y<-rnorm(100,mean=100,sd=50)
#'       x1<-rnorm(150,mean=50,sd=50)
#'       x2<-rnorm(150, mean=50, sd=25)
#'       x<-cbind(x1,x2)
#'       x.tr <- x[1:100,]
#'       x.ts <- x[101:150,]
#'       TSLSTM<-ts.lstm(ts=y,
#'                       xreg = x.tr,
#'                       tsLag=2,
#'                       xregLag = 0,
#'                       LSTMUnits=5,
#'                       ScaleInput = 'scale',
#'                       ScaleOutput = 'scale',
#'                       Epochs=2)
#'       current_values <- predict(TSLSTM, xreg = x.tr, ts = y)
#'       future_values <- predict(TSLSTM, horizon=50, xreg = x, ts = y, xreg.new = x.ts)
#'    }
#' }
#' @importFrom utils tail
#' @importFrom utils capture.output
#' @export
predict.LSTMModel <-  function(object,
           ts,
           xreg = NULL,
           xreg.new = NULL,
           horizon = NULL,
           BatchSize = NULL,
           ...) {

  # Calculate how many samples we need from inputs and output based on lags
  max_lags <- max(c(object$tsLag, object$xregLag))

  # Check if there are enough samples in ts
  if (length(ts) < max_lags) {
    stop(
      "Not enough samples in the time series data (ts) to create the necessary lags for the model."
    )
  }
  freq_ts <- frequency(ts)
  end_ts <- end(ts)

  if (!is.null(object$scale_output)) {
    if (object$scale_output == 'scale') {
      ts <- scale(ts, center = object$scaler_output$center, scale = object$scaler_output$scale)
    }
    if (object$scale_output == 'minmax'){
      ts <- minmax_scale(ts, min = object$scaler_output$min, range = object$scaler_output$range)
    }
  }

  if (!is.null(xreg)){
    # Check if there are enough samples in xreg, if xreg is provided
    row_xreg <- ifelse(is.null(dim(xreg)), length(xreg), dim(xreg)[1])
    if (!is.null(xreg) && (row_xreg < (max_lags))) {
      stop(
        "Not enough samples in the exogenous variables (xreg) to create the necessary lags for the model."
      )
    }

    # Check if input shall be scaled
    if (!is.null(object$scale_input)) {
      if (object$scale_input == 'scale') {
        xreg <- scale(xreg, center = object$scaler_input$center, scale = object$scaler_input$scale)
      }
      if (object$scale_input == 'minmax') {
        xreg <- minmax_scale(xreg, min = object$scaler_input$min, range = object$scaler_input$range)
      }
    }
  }

  if (object$stateful) {
    object$lstm_model %>% reset_states()
  }

  if (!is.null(horizon)) {
    if (!is.null(xreg)){
      if (is.null(xreg.new)) {
        stop("New data of exogenous variables is needed.")
      }
      row_xreg <- ifelse(is.null(dim(xreg.new)), length(xreg.new), dim(xreg.new)[1])
      if (row_xreg < horizon) {
        stop(
          "Not enough samples in the exogenous variables (xreg.new) to predict."
        )
      }
    }

    # Check if new input shall be scaled
    if (!is.null(object$scaler_input)) {
      if (object$scale_input == 'scale') {
        xreg.new <- scale(xreg.new, center = object$scaler_input$center, scale = object$scaler_input$scale)
      }
      if (object$scale_input == 'minmax') {
        xreg.new <- minmax_scale(xreg.new, min = object$scaler_input$min, range = object$scaler_input$range)
      }
    }

    prediction_normalized <- numeric(horizon + 1)

    # Loop for each step in the prediction horizon
    batch_size <- ifelse(is.null(BatchSize) || object$stateful, object$batch_size, BatchSize)

    total_batches <- ceiling(horizon / batch_size)

    # Data Array Preparation for LSTM
    if (!is.null(xreg)){
      feature <- ifelse(is.null(dim(xreg)), ncol(xreg), dim(xreg)[2]) + ifelse(is.null(object$tsLag), 0, 1)
    } else {
      feature <- 1
    }

    if (object$stateful) {
      # Prepare data for prediction
      data <- ts.prepare.data(ts, xreg, object$tsLag, object$xregLag)

      inputs <- data[, -1]

      x_lstm <- array(data.matrix(inputs), c(dim(inputs)[1],
                                             max(c(object$tsLag, object$xregLag)),
                                             feature))

      # Update states of lstm object with training data
      padding_needed <- batch_size - dim(x_lstm)[1] %% batch_size

      # Create padding - an array of zeros with the same shape as x_lstm
      # Assuming your features are the last dimension
      padding <- array(0, dim = c(padding_needed, dim(x_lstm)[2], dim(x_lstm)[3]))

      # Append the padding to x_lstm
      x_lstm <- abind::abind(padding, x_lstm, along=1)


      object$lstm_model %>% predict(x_lstm)

    }

    for (batch in 1:total_batches) {
      # Determine the number of predictions to make in this batch
      predictions_this_batch <- min(batch_size, horizon - (batch - 1) * batch_size)
      start_index <- (batch - 1) * batch_size + 1
      end_index <- start_index + predictions_this_batch - 1

      # Add new data to exogenous variables
      if (!is.null(xreg)) {
        xreg <- rbind(xreg, xreg.new[start_index:end_index,,drop=FALSE])
      }

      # Prepare the data for prediction
      data <- ts.prepare.data(tail(ts, n=max_lags + predictions_this_batch),
                              tail(xreg, n=max_lags + predictions_this_batch),
                              object$tsLag, object$xregLag)

      # Update the lags
      data[,2:(object$tsLag + 1)] <- data[,1:object$tsLag]

      # Split between inputs and output
      inputs <- data[, -1, drop=FALSE]
      if (!object$lags_as_sequences) {
        # Data Array Preparation for LSTM
        x_lstm <- data.matrix(inputs)
        dim(x_lstm) <- c(dim(x_lstm)[1], 1, dim(x_lstm)[2])

        # Model evaluation and prediction on test data
        current_prediction <- object$lstm_model %>% predict(x_lstm)

        # Add current_prediction as last_sample of ts
        ts <- c(ts, current_prediction[,])

        # Add current prediction
        prediction_normalized[start_index:end_index] <- current_prediction[,]
      } else {
        x_lstm <- array(data.matrix(inputs),
                        c(dim(inputs)[1],
                          max(c(object$tsLag, object$xregLag)),
                          feature))
        x_lstm <- x_lstm[,dim(x_lstm)[2]:1,, drop=FALSE] # Reverse order of lags

        if (batch == total_batches && predictions_this_batch < batch_size) {
          padding_needed <- batch_size - predictions_this_batch

          # Create padding - an array of zeros with the same shape as x_lstm
          # Assuming your features are the last dimension
          padding <- array(0, dim = c(padding_needed, dim(x_lstm)[2], dim(x_lstm)[3]))

          # Append the padding to x_lstm
          x_lstm <- abind::abind(x_lstm, padding, along=1)
        }

        # Model evaluation and prediction on test data
        current_prediction <- object$lstm_model %>% predict(x_lstm)

        # Add current_prediction as last_sample of ts
        ts <- c(ts, current_prediction[,])

        # Add current prediction
        prediction_normalized[start_index:end_index] <- current_prediction[,]

      }
    }
    prediction_normalized <- prediction_normalized[1:(length(prediction_normalized) - 1)]
  } else {
    # Prepare data for prediction
    data <- ts.prepare.data(ts, xreg, object$tsLag, object$xregLag)

    # Split between inputs and output
    inputs <- data[, -1, drop=FALSE]
    if (!object$lags_as_sequences) {
      # Data Array Preparation for LSTM
      x_lstm <- data.matrix(inputs)
      dim(x_lstm) <- c(dim(x_lstm)[1], 1, dim(x_lstm)[2])

      # Model evaluation and prediction on test data
      prediction_normalized <- object$lstm_model %>% predict(x_lstm)
    } else {
      # Data Array Preparation for LSTM
      if (!is.null(xreg)){
        feature <- ifelse(is.null(dim(xreg)), ncol(xreg), dim(xreg)[2]) + ifelse(is.null(object$tsLag), 0, 1)
      } else {
        feature <- 1
      }

      x_lstm <- array(data.matrix(inputs), c(dim(inputs)[1],
                                             max(c(object$tsLag, object$xregLag)),
                                             feature))
      x_lstm <- x_lstm[,dim(x_lstm)[2]:1,, drop=FALSE] # Reverse order of lags

      if (object$stateful) {
        # Calculate the padding required
        total_samples <- dim(x_lstm)[1]
        batch_size <- object$batch_size
        padding_needed <- batch_size - (total_samples %% batch_size)
        padding_needed <- ifelse(padding_needed == batch_size, 0, padding_needed)

        # Pad the data
        feature <- dim(x_lstm)[3]
        timesteps <- dim(x_lstm)[2]
        padding <- array(0, dim = c(padding_needed, timesteps, feature))
        x_lstm_padded <- abind::abind(x_lstm, padding, along=1)

        # Make predictions
        prediction_normalized <- object$lstm_model %>% predict(x_lstm_padded)

        # Remove predictions corresponding to the padding, if necessary
        if (padding_needed > 0) {
          prediction_normalized <- prediction_normalized[1:(total_samples), , drop = FALSE]
        }
      } else {
        # Model evaluation and prediction on test data
        prediction_normalized <- object$lstm_model %>% predict(x_lstm)

      }
    }
  }

  predicted_values <- prediction_normalized
  if (!is.null(object$scale_output)) {
    if (object$scale_output == 'scale') {
      predicted_values <- prediction_normalized * object$scaler_output$scale + object$scaler_output$center
    }

    if (object$scale_output == 'minmax') {
      predicted_values <- prediction_normalized * object$scaler_output$range + object$scaler_output$min
    }
  }

  if (is.null(horizon)) {
    return(ts(predicted_values,
              frequency=freq_ts,
              end=end_ts[1] + (end_ts[2] - 1)/freq_ts
    ))
  } else {
    return(ts(predicted_values,
              frequency=freq_ts,
              start=end_ts[1] + end_ts[2]/freq_ts
    ))
  }
}

#' Summary of a Trained LSTM Model
#'
#' @description This function generates the summary of the LSTM model.
#'
#' @param object An LSTMModel object containing a trained LSTM model along with normalization parameters and lag values.
#' @param ... Optional arguments, no use is contemplated right now
#' @return A vector containing the forecasted values for the specified horizon.
#' @examples
#' \donttest{
#'   if (keras::is_keras_available()){
#'       y<-rnorm(100,mean=100,sd=50)
#'       x1<-rnorm(100,mean=50,sd=50)
#'       x2<-rnorm(100, mean=50, sd=25)
#'       x<-cbind(x1,x2)
#'       TSLSTM<-ts.lstm(ts=y,
#'                       xreg = x,
#'                       tsLag=2,
#'                       xregLag = 0,
#'                       LSTMUnits=5,
#'                       ScaleInput = 'scale',
#'                       ScaleOutput = 'scale',
#'                       Epochs=2)
#'       # Assuming TSLSTM is an LSTMModel object created using ts.lstm function
#'       summary(TSLSTM)
#'   }
#' }
#'
#' @export
summary.LSTMModel <- function(object, ...) {
  cat(object$model_structure, sep = "\n")
}

#' Min-Max Scaling of a Matrix
#'
#' @description This function applies min-max scaling to a matrix. Each column of the matrix is scaled independently.
#' The scaling process transforms the values in each column to a specified range, typically [0, 1]. The function
#' subtracts the minimum value of each column (if `min` is `TRUE` or a numeric vector) and then divides by the range
#' of each column (if `range` is `TRUE` or a numeric vector).
#'
#' @param x A numeric matrix whose columns are to be scaled.
#' @param min Logical or numeric vector. If `TRUE`, the minimum value of each column is subtracted.
#' If a numeric vector is provided, it must have a length equal to the number of columns in `x`,
#' and these values are subtracted from each corresponding column.
#' @param range Logical or numeric vector. If `TRUE`, each column is divided by its range.
#' If a numeric vector is provided, it must have a length equal to the number of columns in `x`,
#' and each column is divided by the corresponding value in this vector.
#' @return A matrix with the same dimensions as `x`, where each column has been scaled according to the min-max scaling process.
#'
#' @examples
#' \donttest{
#'   data <- matrix(rnorm(100), ncol = 10)
#'   scaled_data <- minmax_scale(data)
#' }
#'
#' @export
minmax_scale <- function(x, min = TRUE, range = TRUE) {
  x <- as.matrix(x)
  nc <- ncol(x)

  # Apply minimum subtraction
  if (is.logical(min)) {
    if (min) {
      min_values <- apply(x, 2, min, na.rm = TRUE)
      x <- sweep(x, 2, min_values, FUN = "-", check.margin = FALSE)
    }
  }
  else if (is.numeric(min) && length(min) == nc) {
    x <- sweep(x, 2, min, FUN = "-", check.margin = FALSE)
  }
  else {
    stop("length of 'min' must equal the number of columns of 'x'")
  }

  # Apply range division
  if (is.logical(range)) {
    if (range) {
      range_values <- apply(x, 2, max, na.rm = TRUE) - apply(x, 2, min, na.rm = TRUE)
      x <- sweep(x, 2, range_values, FUN = "/", check.margin = FALSE)
    }
  }
  else if (is.numeric(range) && length(range) == nc) {
    x <- sweep(x, 2, range, FUN = "/", check.margin = FALSE)
  }
  else {
    stop("length of 'range' must equal the number of columns of 'x'")
  }

  # Store attributes
  if (is.logical(min)) attr(x, "scaled:min") <- min_values
  if (is.logical(range)) attr(x, "scaled:range") <- range_values
  x
}
