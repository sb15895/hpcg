from utils import* 

parser = argparse.ArgumentParser(
                    prog = 'ProgramName',
                    description = 'What the program does',
                    epilog = 'Text at the bottom of help')

parser.add_argument('--save', action='store_true')  # if save used then fig is saved, otherwise plt.show
parser.add_argument('--name')  # if save used then fig is saved, otherwise plt.show
args = parser.parse_args()

path = f"{os.getcwd()}/6Feb" 

data = HPCG_iocomp_timers(path) # output multi level dict with all information 

effectiveBW_HPCG(data) # plot of effective BW for HPCG 


