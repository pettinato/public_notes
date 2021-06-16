"""
Sample Python script with logging and argparse.

To demo run once as
python3 sample_script.py --log_file run1.log
python3 sample_script.py --log_file run2.log --arg1 hello --arg2 world
python3 sample_script.py --log_file run3.log --arg1 hello --arg2 world --throw

All logging lines will be logged to stdout as well as to the log file.

Any exceptions will also be logged to stdout and the log file.

This allows for running a script unattended and to properly have the exceptions logged to the log file.
"""

import os
import sys
import pprint
import time
import logging
import argparse
import traceback
import pandas as pd


# Setup libraries
logger = logging.getLogger('default_logger')
pprinter = pprint.PrettyPrinter(width=1)
pd.set_option('display.max_colwidth', -1)  # Allow no truncation of any dataframe columns


class ArgParseFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter):
    """
    Helper class for ArgParse to have both better formatting
    and to auto print default argument values
    """
    pass


def setup_logging(log_file='log_build_recs.out'):
    """
    Setup logging to log to stdout and a file
    :param log_file: Filename for the log
    """
    # If logger is already configured
    if logger.handlers != []:
        return

    if os.path.exists(log_file):
        print("Deleting existing log file: {}".format(log_file))
        os.remove(log_file)
    print("Logging to file {}".format(log_file))

    logging_formatter = logging.Formatter(fmt="%(asctime)s: %(levelname)s: %(message)s")

    # Setup the stream handler
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(logging_formatter)
    logger.addHandler(stream_handler)

    # Setup the file handler
    file_handler = logging.FileHandler(log_file)
    file_handler.setFormatter(logging_formatter)
    logger.addHandler(file_handler)

    logger.setLevel(logging.INFO)

    # logger = logging.getLogger(__name__)
    logger.info("Logging to file %s" % log_file)


def sample_function(arg1, arg2, throw):
    """
    Sample function. If throw is true, throw an exception
    :param arg1: First argument
    :param arg2: Second argument
    """
    logger.info("Start sample_function with arg1={arg1} arg2={arg2} throw={throw}".format(
        arg1=arg1, arg2=arg2, throw=throw))

    if throw:
        1 / 0
    logger.info("Finish sample_function")


def main(raw_args):
    """
    Read in all arguments and process
    :param raw_args: Raw command line arguments to be processed by argparse.
    """

    start_time_sec = time.time()

    description = "\n".join([
        "Sample Python script with logging and argparse.",
        "To demo run once as",
        "python3 sample_script.py --log_file run1.log",
        "python3 sample_script.py --log_file run2.log --arg1 hello --arg2 world",
        "python3 sample_script.py --log_file run3.log --arg1 hello --arg2 world --throw",
        "All logging lines will be logged to stdout as well as to the log file.",
        "Any exceptions will also be logged to stdout and the log file.",
        "This allows for running a script unattended ",
        "and to properly have the exceptions logged to the log file."])

    parser = argparse.ArgumentParser(description=description, formatter_class=ArgParseFormatter)
    parser.add_argument('-a', '--arg1', type=str, required=False, default='arg1default',
                        help='Sample argument 1')
    parser.add_argument('-b', '--arg2', type=str, required=False, default='arg2default',
                        help='Sample argument 2')
    parser.add_argument('-t', '--throw', action='store_true', required=False,
                        help="If true, an exception will be thrown")
    parser.add_argument('-l', '--log_file', type=str, required=False, default='sample.log',
                        help="File to use for logging")
    args = vars(parser.parse_args(raw_args))

    setup_logging(args['log_file'])

    logger.info('-' * 40)
    logger.info('Script Arguments\n%s' % pprinter.pformat(args))
    logger.info('-' * 40)

    # Build the recommendations for every date
    try:
        sample_function(args['arg1'], args['arg2'], args['throw'])
        logger.info("Finished processing")
    except:
        logger.error(traceback.format_exc())

    logger.info("\nDone. Took %0.2f minutes to run..." % ((time.time() - start_time_sec) / 60.))


if __name__ == '__main__':
    main(sys.argv[1:])
